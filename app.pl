#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Redis2;
use Mojo::JSON qw/decode_json encode_json true/;
use Encode qw/encode_utf8/;

app->config(
    hypnotoad => {
        listen => [ 'http://*:' . $ENV{PORT} ],
    },
    redis => {
        server => $ENV{REDISTOGO_URL} || 'redis://127.0.0.1:6379',
        subscribe => 'channel:livereload'
    },
);

get '/' => 'index';

get '/hook' => sub {
    my $c = shift;
    $c->app->log->debug("hook!");

    unless ( $c->param('key') ){
        return $c->render(json => {r => 'denied'});
    }
    unless ( $ENV{KEY} eq $c->param('key') ){
        return $c->render(json => {r => 'denied'});
    }

    my $config = $c->app->config->{redis};
    my $redis = Mojo::Redis2->new( url => $config->{server} );
    $redis->publish($config->{subscribe} => encode_json({
        command => 'reload',
        path => '/',
        liveCSS => true
    }));
    $c->render(json => {r => 'publish'});
};

websocket '/livereload' => sub {
    my $c = shift;
    $c->inactivity_timeout(30);

    $c->app->log->debug("websocket opened");

    my $config = $c->app->config->{redis};
    my $redis = Mojo::Redis2->new( url => $config->{server} );

    my $sub = $redis->subscribe([ $config->{subscribe} ]);
    $sub->on(
        message => sub {
            my ( $redis, $data ) = @_;
            $c->send( { json => decode_json($data) } );
        }
    );

    $c->on(
        message => sub {
            my ( $c, $msg ) = @_;
            my $data = decode_json( encode_utf8($msg) );
            if ( $data->{command} eq 'hello' ) {
                my $hello_response = {
                    command   => 'hello',
                    protocols => [
                        'http://livereload.com/protocols/official-7',
                    ],
                    serverName =>  'my livereload gateway proxy/0.1'};
                $c->send( { json => $hello_response } );
                return;
            }
        }
    );

    $c->on(
        finish => sub {
            my ( $c, $code, $reason ) = @_;
            $c->app->log->debug("websocket closed with status $code");
            delete $c->stash->{redis};
        }
    );

    $c->stash( redis => $redis );
};

app->start;
__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>my livereload gateway proxy</title>
  <meta name="robots" content="noindex,nofollow">
  <style> pre { border:1px solid #666; padding:10px; }</style>
</head>
<body>
  <h1>my livereload gateway proxy</h1>
  <h2>これはなに?</h2>
  <p><a href="http://livereload.com">http://livereload.com</a> が開発サーバーなどで稼働させることができない人のためのプログラムです。<br>何らかのきっかけをcurlでherokuに動かしているこのプログラムに送信することで、ブラウザに対して中継します。</p>
  <h2>動かしかた</h2>
  <h3>HTML側</h3>
  <p>livereload.jsを入れます。</p>
  <pre>&lt;script src="https://<script>document.write(location.host);</script>/livereload.js"&gt;&lt;/script&gt;</pre>
  <h3>変更の通知のしかた</h3>
  <p>curlでGETします</p>
  <pre> curl http(s)://<script>document.write(location.host);</script>/hook?key=(herokuの設定) </pre>
</body>
</html>
