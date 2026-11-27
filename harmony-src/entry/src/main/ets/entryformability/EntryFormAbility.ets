// 卡片提供方：定时/点击刷新时拉取 card.json 并更新卡片
import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { fetchCard, loadCache, saveCache, EMPTY_CARD, parseCard, CardData } from '../common/CardData';
import { maybeTriggerRelay } from '../common/RelayTrigger';

function toFormJson(data: CardData): string {
  return JSON.stringify(data);
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    // formId 从 want 参数里取（FormExtensionContext 没有 formId 属性）
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    if (formId) {
      this.refresh(formId).catch(() => {});
    }
    return formBindingData.createFormBindingData({ dataJson: JSON.stringify(EMPTY_CARD) });
  }

  onUpdateForm(formId: string): void {
    // 系统定时刷新（最小 30 分钟一次）
    this.refresh(formId).catch(() => {});
  }

  onFormEvent(formId: string, message: string): void {
    // 卡片上的「刷新」按钮触发
    this.refresh(formId).catch(() => {});
  }

  private async refresh(formId: string): Promise<void> {
    // 1. 先把现有数据刷到卡片上（用户马上能看到东西）
    const fresh = await fetchCard();
    if (fresh) {
      const data = parseCard(fresh);
      if (data.news) {
        await saveCache(this.context, fresh);
        await formProvider.updateForm(formId, formBindingData.createFormBindingData({ dataJson: fresh }));
      }
    }
    // 2. 再让 GitHub 跑一次 relay；下次刷新就能拿到新数据
    //    没有 token 文件时这里直接返回，不影响卡片
    await maybeTriggerRelay(this.context).catch(() => {});
  }
}
