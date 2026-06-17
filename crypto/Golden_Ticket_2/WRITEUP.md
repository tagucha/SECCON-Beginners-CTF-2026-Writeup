# Golden Ticket 2

これは、AES-CBCがテーマの問題です。一般にCBCモードではIVを固定すると安全でなくなることが知られています。今回はIVが固定されている脆弱性は使います。しかしながら、暗号化は3回しかできず、復号した平文に対してパディングのバリデーションがかけられているなどの制約があります。ここをどう処理するのかが課題でした。

## フラグ取得条件

まず、フラグを取得するために何をすれば良いのかを見ます。

フラグは `Get flag` から取得できますが、この処理では `golden ticket` が1枚必要です。

```python
if i == 4:
    consume_ticket(golden=1)
    print("flag:", flag)
```

一方で、`golden ticket` は最初から持っているわけではありません。`Get ticket` に成功すると増えます。

```python
if cipher.decrypt(answer[16:]) == challenge:
    print("Correct!")
    key = os.urandom(16)
    GOLDEN_TICKET += 0.25
```

ここで増える量は `0.25` なので、フラグを取得するには `Get ticket` を4回成功させる必要があります。

また、成功するたびに `key` は更新されますが、`iv` と `challenge` は更新されません。

## Get ticket の成功条件

次に、`Get ticket` の処理を見ます。

```python
print("challenge:", challenge.hex())
answer = bytes.fromhex(input("answer> "))
if len(answer) != len(challenge) + 16:
    print("Wrong length.")
    continue
cipher = AES.new(key, AES.MODE_CBC, iv=answer[:16])
if cipher.decrypt(answer[16:]) == challenge:
    print("Correct!")
```

`challenge` は `16 * 6` byte、つまりAESの6ブロック分です。

提出する `answer` は `challenge + 16` byte の長さである必要があります。そして、先頭16 byteはCBCのIVとして使われます。

したがって、提出する `answer` を次のように置きます。

```text
IV || C1 || C2 || C3 || C4 || C5 || C6
```

## CBC復号の式にする

`challenge` を6ブロックに分けます。

```text
M1 || M2 || M3 || M4 || M5 || M6
```

CBC復号では、各ブロックは次のように復号されます。

```text
D_K(C1) xor IV = M1
D_K(C2) xor C1 = M2
D_K(C3) xor C2 = M3
D_K(C4) xor C3 = M4
D_K(C5) xor C4 = M5
D_K(C6) xor C5 = M6
```

つまり、後ろから順番に作ればよいです。

```text
C5 = D_K(C6) xor M6
C4 = D_K(C5) xor M5
C3 = D_K(C4) xor M4
C2 = D_K(C3) xor M3
C1 = D_K(C2) xor M2
IV = D_K(C1) xor M1
```

この形を見ると、AESの鍵 `key` そのものを求める必要はありません。

必要なのは、いくつかのブロック `X` について、

```text
D_K(X)
```

を得ることです。

## 暗号化オラクルで得られるもの

暗号化機能では、最大16 byteの平文をAES-CBCで暗号化できます。

```python
cipher = AES.new(key, AES.MODE_CBC, iv=iv)
print(f"ct:", cipher.encrypt(pad(pt, 16)).hex())
```

ここで16 byteちょうどの平文 `P` を暗号化します。

PKCS#7 paddingにより、実際に暗号化される平文は2ブロックになります。

```text
P || 10 10 ... 10
```

暗号文を

```text
C1 || C2
```

とすると、CBC暗号化は次のようになります。

```text
C1 = E_K(P xor IV)
C2 = E_K(C1 xor 10...10)
```

したがって、

```text
D_K(C2) = C1 xor 10...10
```

が分かります。

つまり、暗号化を1回使うと、少なくとも1つのブロックについて `D_K(X)` が分かります。

## 復号オラクルの制約

復号機能では、最大32 byte、つまり2ブロックまで復号できます。

```python
cipher = AES.new(key, AES.MODE_CBC, iv=iv)
print("pt:", unpad(cipher.decrypt(ct), 16).hex())
```

ただし、復号結果に対して `unpad()` が呼ばれています。

そのため、最後のブロックが正しいPKCS#7 paddingになっていないと例外で落ちます。

つまり、復号オラクルは自由に使えるわけではありません。

```text
不正なpadding -> 接続が落ちる
正しいpadding -> 復号結果が得られる
```

という制約があります。

## padding制約を満たしながら `D_K(X)` を増やす

復号オラクルは便利ですが、何でも自由に復号できるわけではありません。

復号処理では、復号結果に対して `unpad()` が呼ばれます。

```python id="quv4pa"
print("pt:", unpad(cipher.decrypt(ct), 16).hex())
```

そのため、最後のブロックが正しいPKCS#7 paddingになっていないと、例外で接続が落ちます。

つまり、復号オラクルを使うときは、必ず最後のブロックがvalid paddingになるように暗号文を作る必要があります。

ここで、すでにあるブロック `C` について、

```text id="d8lmdn"
D_K(C) = R
```

が分かっているとします。

この `C` を2ブロック目に置いて、復号オラクルに次の2ブロックを投げます。

```text id="n08xnn"
B || C
```

このときCBC復号結果は次のようになります。

```text id="1akk7e"
P1 = D_K(B) xor IV
P2 = D_K(C) xor B
```

ここで `D_K(C) = R` は既知なので、

```text id="q6tqaf"
P2 = R xor B
```

です。

`unpad()` が見るのは最後のブロック `P2` です。
したがって、`P2` がvalid paddingになれば、復号オラクルは落ちずに結果を返してくれます。

一番簡単なのは、`P2` の末尾1 byteを `0x01` にすることです。

PKCS#7では、末尾が `0x01` なら、最後の1 byteだけがpaddingとして扱われます。この場合、前の15 byteは何でも構いません。

つまり、

```text id="7sgw89"
P2[-1] = 0x01
```

になればよいです。

`P2 = R xor B` なので、

```text id="kc57yw"
R[-1] xor B[-1] = 0x01
```

を満たせばよいです。

したがって、`B` の末尾1 byteを次のように決めます。

```text id="mdoa82"
B[-1] = R[-1] xor 0x01
```

これで、

```text id="s0eeiq"
P2[-1] = R[-1] xor B[-1]
       = R[-1] xor (R[-1] xor 0x01)
       = 0x01
```

となり、必ずvalid paddingになります。

このとき、復号オラクルの出力は `unpad()` 後の値です。
`P2` の末尾1 byteだけが削られるので、出力は次の形になります。

```text id="pa9gz5"
P1 || P2[:15]
```

つまり、出力の先頭16 byteはそのまま

```text id="bldfyh"
P1 = D_K(B) xor IV
```

です。

ここで、固定のオラクル用IVが既に分かっていれば、

```text id="q0gf47"
D_K(B) = P1 xor IV
```

として、新しいブロック `B` について `D_K(B)` を得られます。

まとめると、次のようになります。

```text id="k21wcu"
既知:
  D_K(C) = R

作る:
  B[-1] = R[-1] xor 0x01

復号に投げる:
  B || C

すると:
  2ブロック目 = R xor B
  その末尾は 0x01
  よって unpad が通る

得られる:
  出力の先頭16 byte = D_K(B) xor IV

IV が既知なら:
  D_K(B) = 出力の先頭16 byte xor IV
```

これにより、既知の `D_K(C)` を1つ持っていれば、padding制約を満たしながら新しい `D_K(B)` を得ることができます。

ただし、ここで得られる `B` は完全に任意ではありません。
`B[-1] = R[-1] xor 0x01` という条件があります。

そのため、任意のブロック `X` について `D_K(X)` を知りたい場合は、`D_K(C)` の末尾が

```text id="nu89ju"
D_K(C)[-1] = X[-1] xor 0x01
```

になっているような既知ブロック `C` が必要です。

既知ブロックを増やしていくと、`D_K(C)` の末尾byteもばらけていきます。
そこで、末尾byteごとに既知ブロックを集めておけば、必要な末尾byteを持つ `C` を選んで、任意の `X` に対する `D_K(X)` を安全に得られるようになります。


## IVをどう得るか

暗号化で得た2ブロック目 `C2` については、

```text
D_K(C2) = C1 xor 10...10
```

が分かっています。

したがって、`C2` を1ブロック暗号文として復号に投げたとき、たまたまpaddingが正しければ、

```text
D_K(C2) xor IV
```

が得られます。

すると、

```text
IV = D_K(C2) xor leaked
```

でIVを求められます。

ただし、ランダムな復号結果がvalid paddingになる確率は約 `1/255` です。失敗すると接続が落ちるので、成功する接続を引くまで試します。

## 暗号化チケットが3枚しかない問題

`Get ticket` は4回成功させる必要があります。

しかし、暗号化チケットは3枚しかありません。

```text
ENC_TICKET = 3
GOLDEN_TICKET += 0.25
```

さらに、`Get ticket` に成功するたびに `key` が更新されます。

そのため、暗号化で得た `D_K(X)` の情報は、次のkeyでは使えません。

つまり、4回のうち1回は暗号化を使わずに、復号だけで最初の`D_K(X)`を作る必要があります。

IVは一度求めれば固定なので使い回せます。そこで、暗号化チケットを使わない回では、ランダムな1ブロックを復号に投げます。

たまたまpaddingがvalidなら、

```text
D_K(X) xor IV
```

が得られます。

IVは既知なので、

```text
D_K(X)
```

を得られます。

これも成功確率は約 `1/255` です。

## 全体の流れ

最終的な流れは次のようになります。

```text
1. 暗号化を1回使って D_K(C2) が分かるブロックを作る
2. 約1/255の確率でIVを回収する
3. 既知の D_K(X) を復号オラクルで増やす
4. CBC-Rで challenge を復号結果にする answer を作る
5. Get ticket に成功する
6. key が更新される
7. 同じ challenge に対して再び answer を作る
8. これを合計4回成功させる
```

必要なランダム成功は主に2回です。

```text
IV回収: 約1/255
暗号化なしでD_K(X)を通す: 約1/255
```

したがって、全体としてはおおよそ

```text
(1/255)^2
```

のガチャを通す必要があります。大体4.5万回の試行での成功確率が`50%`なので、そこそこ待たないと出てきません。

これを迷惑にならないレベルで並列に試していけばフラグが得られます。