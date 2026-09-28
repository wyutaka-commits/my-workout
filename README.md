# MY WORKOUT v2

iPhone / Android のSafari・Chromeで使えるPWA試作版です。

## iPhoneで使う手順

1. このフォルダをWeb上に公開します。
2. iPhoneのSafariで公開URLを開きます。
3. 画面下の「共有」をタップします。
4. 「ホーム画面に追加」を選びます。
5. ホーム画面の「MY WORKOUT」から起動します。

## GitHub Pagesで無料公開する場合

1. GitHubで新しいリポジトリを作成します（例: my-workout）。
2. このフォルダの中身をすべてアップロードします。
3. GitHubの Settings → Pages を開きます。
4. Build and deployment で「Deploy from a branch」を選び、main / root を指定します。
5. 数分後に表示されるURLをiPhoneのSafariで開きます。

## 注意

この試作版のリマインド通知は、ブラウザ・OSの制約上、アプリを閉じていても必ず通知される仕組みではありません。
本格運用ではWeb Push用のサーバー機能を追加する必要があります。

データは基本的に端末内（localStorage）に保存します。機種変更・ブラウザデータ削除時には引き継がれません。
