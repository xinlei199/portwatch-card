// 4×4 桌面卡片（约半屏）
// 注意：postCardAction 是卡片内全局函数，不能从 @kit.ArkUI 导入
import { CardData, EMPTY_CARD, NewsItem, parseCard, relTime } from '../../common/CardData';

@Entry
@Component
struct PortCard {
  @LocalStorageProp('dataJson') @Watch('onDataChange') dataJson: string = '';
  @State d: CardData = EMPTY_CARD;

  aboutToAppear(): void {
    this.d = parseCard(this.dataJson);
  }

  onDataChange(): void {
    this.d = parseCard(this.dataJson);
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Text('GTA6 · PC 移植进度')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
        Blank()
        Text(relTime(this.d.updatedAt))
          .fontSize(9)
          .fontColor('#9C8FB8')
      }
      .width('100%')

      // 进度
      Column() {
        Row() {
          Text(this.d.top ? this.d.top.score.toFixed(1) + '%' : '--')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Blank()
          Text(this.d.top ? this.d.top.reachedZh : '加载中')
            .fontSize(11)
            .fontColor('#FFB347')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#33FFB347')
            .borderRadius(8)
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)

        Progress({ value: this.d.top ? this.d.top.score : 0, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(6)
          .color('#FF6B35')
          .backgroundColor('#33FFFFFF')
          .borderRadius(3)
          .margin({ top: 6 })

        Text(this.d.top ?
          ('榜首 ' + this.d.top.name + (this.d.top.fps ? (' · ' + this.d.top.fps + ' FPS') : '')) : ' ')
          .fontSize(10)
          .fontColor('#B0A8C0')
          .margin({ top: 4 })
      }
      .width('100%')
      .margin({ top: 10 })

      // 最新消息
      Column() {
        if (this.d.news.length === 0) {
          Text('正在获取最新消息…')
            .fontSize(10)
            .fontColor('#8A80A0')
        } else {
          ForEach(this.d.news.slice(0, 3), (n: NewsItem) => {
            Text('· ' + n.titleZh)
              .fontSize(10)
              .fontColor('#E0DAF0')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 3 })
          }, (n: NewsItem) => n.link)
        }
      }
      .width('100%')
      .margin({ top: 8 })

      Blank()

      // 底栏
      Row() {
        Button('刷新')
          .fontSize(10)
          .height(24)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#33FFFFFF')
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => {
            postCardAction(this, { action: 'message', params: { type: 'refresh' } });
          })
        Blank()
        Text('详情 ›')
          .fontSize(10)
          .fontColor('#8A80A0')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .linearGradient({
      angle: 135,
      colors: [['#160A28', 0], ['#2B1848', 0.6], ['#3A1F5C', 1]],
    })
    .borderRadius(20)
    .onClick(() => {
      postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: {} });
    })
  }
}
