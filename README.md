# SHRIFT Translation

The following files are not compatible with RPG Maker Trans:

-Graphics.txt
-Comment.txt

Those files are used by the auto-translator to do what RPG Maker Trans can't do.

-------------------------------------------
Graphics (for picture translation):

> BEGIN STRING
現実の空間
魔力
虚数空閻(何もない次元)
結界空間

妄想力プセル
結界空間#Lvl1VillagerA <---- Whoever identified the characters in \Graphics\Pictures\53.png
> CONTEXT: \Graphics\Pictures\53.png <--- context is the path from game folder
Real space
Magical power
Imaginary number space (nothing dimension)
Boundary space

Delusion power pseudo
Boundary space#MTLed <---- Whoever translated the text in \Graphics\Pictures\53.png
> END STRING

The translated text will be added to the game picture
Use Google Drive OCR if you want to extract text from a picture.
You can try online dictionaries or Windows IME if you're confident.
-------------------------------------------
Comments (for database notes, comments, and reliable script translation):

Database notes include enemies, classes, actors, etc. notes. They are sometime used:

> BEGIN STRING
<zoom 90>
<図鑑特徴:氷に弱い>

<図鑑説明:ヘカーテの従える使い魔の一種。>
<図鑑説明:黒い体毛の猟犬の姿で現れる邪悪な精霊とされ>
<図鑑説明:バーゲストそのものが死の象徴とされていた。>
<図鑑説明:人の死の際に姿を現し、遠吠えで関係者に知らせる。>
> CONTEXT: Enemies/560/Note
<zoom 90>
<図鑑特徴:Weak to ice>

<図鑑説明:Hecate is a type of demons that Hecate follows.>
<図鑑説明:It is regarded as an evil spirit that appears in the form of a black haired hound dog>
<図鑑説明:The barghest itself was regarded as a symbol of death.>
<図鑑説明:Appears when people are dead and informs concerned people by howling.>#MTLed
> END STRING

Comments exists in Map Events, Troop Events, Common Events. They are sometime used:
> BEGIN STRING
選択肢ヘルプ
選択したセーブデータの状態から
好きなチャプターを選んで開始します。
選べるのは、プレイ済みのチャプター＆進行中のチャプターのみです
> CONTEXT: Map002/214/Comment
選択肢ヘルプ
From the state of the selected saved data
Choose your favorite chapter and start.
You can only select chapters that have been played and
chapters in progress#MTLed
> END STRING

The only scripts whose text is extracted are custom scripts. Thay can be tricky sometimes and RPGMTrans can't be trusted with it.
> BEGIN STRING
"件名：理由
> CONTEXT: Scripts/テキスト出力/5:12
"subject：the reason#MTLed
> END STRING

> BEGIN STRING
 　　　送信者【Richard】
> CONTEXT: Scripts/テキスト出力/6:1
> CONTEXT: Scripts/テキスト出力/246:1
 sender【Richard】#MTLed
> END STRING
