// 详情页：完整新闻列表，点击打开原文
import { common } from '@kit.AbilityKit';
import { CardData, EMPTY_CARD, NewsItem, fetchCard, loadCache, parseCard, relTime, saveCache } from '../common/CardData';

@Entry
@Component
struct Index {
  @State d: CardData = EMPTY_CARD;
  @State loading: boolean = true;
  private ctx = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const cached = await loadCache(this.ctx);
    if (cached) {
      this.d = parseCard(cached);
      this.loading = false;
    }
    const fresh = await fetchCard();
    if (fresh) {
      this.d = parseCard(fresh);
      await saveCache(this.ctx, fresh);
    }
    this.loading = false;
  }

  openLink(link: string): void {
    this.ctx.startAbility({
      action: 'ohos.want.action.viewData',
      uri: link,
    });
  }

  build() {
    Column() {
      Row() {
        Text('GTA6 · PC 移植进度')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Text(relTime(this.d.updatedAt))
          .fontSize(11)
          .fontColor('#B0A8C0')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      // 进度卡
      Column() {
        Row() {
          Text(this.d.top ? this.d.top.score.toFixed(1) + '%' : '--')
            .fontSize(44)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Blank()
          Text(this.d.top ? this.d.top.reachedZh : '')
            .fontSize(13)
            .fontColor('#FFB347')
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)

        Progress({ value: this.d.top ? this.d.top.score : 0, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(8)
          .color('#FF6B35')
          .backgroundColor('#33FFFFFF')
          .borderRadius(4)
          .margin({ top: 8 })

        Text(this.d.top ? ('榜首 ' + this.d.top.name) : ' ')
          .fontSize(12)
          .fontColor('#B0A8C0')
          .margin({ top: 6 })
      }
      .width('90%')
      .padding(18)
      .backgroundColor('#22FFFFFF')
      .borderRadius(16)
      .margin({ top: 12 })

      if (this.loading && this.d.news.length === 0) {
        Text('正在获取…').fontSize(12).fontColor('#8A80A0').margin({ top: 24 })
      }

      // 新闻列表
      List({ space: 10 }) {
        ForEach(this.d.news, (n: NewsItem) => {
          ListItem() {
            Column() {
              Row() {
                Text(n.categoryZh).fontSize(11).fontColor('#FF6B35')
                Blank()
                Text(n.date).fontSize(11).fontColor('#8A80A0')
              }
              .width('100%')

              Text(n.titleZh)
                .fontSize(15)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
                .margin({ top: 4 })

              Text(n.dekZh)
                .fontSize(12)
                .fontColor('#B0A8C0')
                .margin({ top: 4 })
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(14)
            .backgroundColor('#22FFFFFF')
            .borderRadius(12)
            .onClick(() => this.openLink(n.link))
          }
        }, (n: NewsItem) => n.link)
      }
      .width('90%')
      .layoutWeight(1)
      .margin({ top: 12 })

      Text('数据来自 portwatch-vi.xyz · 每 30 分钟刷新')
        .fontSize(9)
        .fontColor('#665C7A')
        .margin({ top: 8, bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 160,
      colors: [['#160A28', 0], ['#0D0718', 1]],
    })
  }
}
