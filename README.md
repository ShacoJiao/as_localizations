## 说明

*   此 package需要在主项目创建 as\_i18n.yaml 配置文件，主项目必须配置&#x20;

*   package 中脚本会生成 相应的arb文件，在主项目中的 assets/translations 下，故需要在主项目的 pubspec.yaml 中 添加assets目录

### as\_i18n.yaml 样例

```yaml
i18n-dir: lib/localizations/
template-json-file: as_i18n.json
output-localization-file: app_localizations.dart
locales:
  - en_US
  - zh_Hans_CN
feature-strings:
  app: app_strings
  common: common_strings
lingo:
  prefix: home_v1_0_1_
  api-path: ""
  token: ""
```

### as\_i18n.yaml 参数说明

| 1级                       | 2级             | 说明                                                                                                                                                                                                                                                                     |
| :----------------------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| i18n-dir                 |                | 处理国际化文案的工作目录                                                                                                                                                                                                                                                           |
| template-json-file       |                | 主项目中，开发人员配置的所有文案字段                                                                                                                                                                                                                                                     |
| output-localization-file |                | LocalizationsSDK 的扩展文件，即相应Feature Strings 生明的扩展                                                                                                                                                                                                                        |
| locales                  |                | 支持的语言列表，可配置: <br>英语 : en\_US<br>简体中文 : zh\_Hans\_CN<br>繁体中文 : zh\_Hant\_HK<br>韩语 : ko\_KR<br>西班牙语 : es\_ES<br>菲律宾语 : fil\_PH<br>法语fr\_FR<br>日语 : ja\_JP<br>葡萄牙语 : pt\_PT<br>泰语 : th\_TH<br>土耳其语 : tr\_TR<br>越南语 : vi\_VN<br>德语: de\_DE<br>意大利语 : it\_IT<br>俄语 : ru\_RU |
| feature-strings          |                | feature 分类，若未声明，则key值对应的方法会生成在  base\_strings.dart 中                                                                                                                                                                                                                   |
|                          | app  (此为自定义生明) | app\_strings.dart => AppStrings 类 => 扩展中为 AppStrings get app => AppStrings();                                                                                                                                                                                          |
| lingo                    |                | 灵果文案拉取配置                                                                                                                                                                                                                                                               |
|                          | prefix         | 需要筛选的前缀，生成arb时默认去掉                                                                                                                                                                                                                                                     |
|                          | api-path       | lingo api path                                                                                                                                                                                                                                                         |
|                          | token          | lingo api token                                                                                                                                                                                                                                                        |

## 脚本

主项目中 只需要执行  translations\_to\_diff.py  即可

| 脚本                           | 用途                                                                                                    |
| :--------------------------- | :---------------------------------------------------------------------------------------------------- |
| check\_and\_fix\_id.dart     | 校验strings文件中的 sid 值                                                                                   |
| clean.dart                   | 清理 自动化生成的文件                                                                                           |
| config\_parser.dart          | 此为读取主项目 as\_i18n.yaml 中的配置                                                                            |
| create\_not\_exist\_arb.dart | 根据 as\_i18n.yaml 配置的locales，创建确实的arb文件，并清理多余的arb文件                                                    |
| diff\_to\_lingo.py           | 将diff.json与diff\_en\_US.json 合并，最后生成 new\_to\_lingo.json，将其上传是 灵果                                     |
| generate.dart                | 初始化as\_i18n.json(若存在不覆盖)，并根据内容，生成对应的strings文件与LocalizationsSDK的Extension，strings的规则在 as\_i18n.yaml 配置 |
| generate\_new\_strings.dart  | 根据现有的strings文件生成 临时arb文件                                                                              |
| openai\_translate.py         | 将diff.json 进行翻译 生成 diff\_en\_US.json                                                                  |

