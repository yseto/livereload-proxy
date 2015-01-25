my livereload gateway proxy
=================

LiveReload Proxy for me.

これはなに?
----------

- http://livereload.com が開発サーバーなどで稼働させることができない人のためのプログラムです。
- 何らかのきっかけをcurlでherokuに動かしているこのプログラムに送信することで、ブラウザに対して中継します。

動かしかた
----------

- HTML側 (livereload.jsを入れます)
  ````
  <script src="https://(動かしているherokuapp.com)/livereload.js"></script>
  ````

- 変更の通知のしかた (curlでGETします)
  ````
  curl http://(動かしているherokuapp.com)/hook?key=(herokuで設定したKEY) 
  ````

On Heroku
----------

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

- 同梱している livereload.js は、 https://github.com/livereload/livereload-js/raw/master/dist/livereload.js から取得してherokuで動作するようにポート番号などを修正しています。

reference
----------
- https://github.com/livereload/livereload-js

License
----------
this product is available under the MIT license.


