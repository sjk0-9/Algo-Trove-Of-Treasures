# Sending ASAs

So you've got a bunch of ASAs you want to distribute to a whole heap of people?
Could do it one at a time through the app, or you could whip up something super quickly in python.

To begin, we'll import the required algorand methods as well as our environment we set up [here](./env_file.md) and the sleep method for waiting on the algorand network.

We'll then create the algorand connections we need, and get the key and address from our mnemonic. If all works, you should see your algorand address printed at the end.


```python
from algosdk.v2client import algod
from algosdk import mnemonic, account
from algosdk.future.transaction import AssetTransferTxn
import env
from time import sleep
```


```python
ac = algod.AlgodClient(env.API_TOKEN, env.ALGOD_ADDRESS, env.API_HEADERS)
private_key = mnemonic.to_private_key(env.MY_PHRASE)
sender_address = account.address_from_private_key(private_key)
sender_address
```




    'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ'



If you've followed the [Creating ASAs tutorial](./creating_asas.md), then you'll be familiar with a lot of what we're doing here.

Algorand has 6 transaction types you can write to the block chain.
In this instance, we use the `axfer` transaction for transferring an ASA.
Python makes this easy with the `AssetTransferTxn` method.

We'll create a simple helper function that wraps it.


```python
def send(assetId, quantity, to, note=None):
    # These are some default details that the transaction requires
    params = ac.suggested_params()
    txn = AssetTransferTxn(
        sender=sender_address,
        sp=params,
        receiver=to,
        amt=quantity,
        index=assetId,
        # Only append a note to the transaction if one exists
        note=str.encode(note) if note is not None else None,
    )
    # Sign it, so the blockchain is confident we're the ones who sent it.
    stxn = txn.sign(private_key)
    # Send it!
    txid = ac.send_transaction(stxn)
    return txid
```


```python
# This is an asset we created as part of the Creating ASAs tutorial
sent_txid = send(
    52057325,
    1,
    'DEMOIQZCE6HX2GMEXPGP3O3QZPMIVHAALJE6LNBVF2ACHIMAITRUFJOQ5M',
    "Hello World!"
)
sent_txid
```




    'KTQIS6MNY7UO5GI2XW4ULNAUF3B2OK2KYYONXGAR44UPXHH5UX4Q'



Now we've got the transaction ID, we want to wait to confirm it's actually been received.

That's a pretty simple check:


```python
def confirm_sent(txid):
    while True:
        tx_info = ac.pending_transaction_info(txid)
        if 'confirmed-round' in tx_info:
            break
        sleep(1)
```


```python
confirm_sent(sent_txid)
```

This function will simply keep calling, waiting for the transaction to confirm.
It won't exit until the recepient has definitely received the asset.

You may want to edit it to count the number of loops waited, and if it seems we're stuck, raise an error to exit.

## Side Note: Opting in

Before moving onto the batch process, it's worth noting that what we've got here is everything we need to be able to opt into an asset.
In algorand, opting into an asset is simply sending a 0 value transaction for an asset to yourself.

So say we wanted to opt into the testnet Wrapped Algo asset (14704676), all we'd need to do is call:


```python
opt_in_txid = send(14704676, 0, sender_address)
confirm_sent(opt_in_txid)
opt_in_txid
```




    'YALCCHENENF2WAJXOOR4CLYD6OTTYBFFFVYUUGCYUNYM4QT5BTGA'



## Batch Sending Assets

Sending batches of assets is now really simple.
You just need a list of all the assets you want to send, and then iterate over it.

This is a really good case for using something like Python's [CSV Reader](https://docs.python.org/3/library/csv.html#csv.DictReader) which lets you store it all in a spreadsheet compatible format.


```python
import csv
# StringIO is only for demo purposes, to simulate opening a file
# Normally you'd use the "open" method for reading into csv files
# As demonstrated in the CSV documentation linked above.
from io import StringIO

CSV_FILE = StringIO("""assetId,quantity,to,note
52057232,50,DEMOIQZCE6HX2GMEXPGP3O3QZPMIVHAALJE6LNBVF2ACHIMAITRUFJOQ5M
52057232,42,DEMOUN4WTPLYTK347QENBTB7BOPJKTA5LIYRR55NIEDLIZRW3IFUV66TGU, A note
52057232,.1,DEMO5BFQEZGQRMAV7DB3ZKGFZC32OO5QKMNJKMRS52PRQ5LCPV7GKKGDWQ
""")

csv_reader = csv.DictReader(CSV_FILE)
transactions = []
for row in csv_reader:
    print(row)
    # Note, CSVs read in all types as strings, so we need to convert some to
    # integers... wait a second, what's with that weird float thing there?
    # So while algorand allows decimal places, and the ASA we created has two
    # Decimals... that only affects how the assets display.
    # When sending assets, you need to send the full amount.
    # e.g. 10 with 2 decimals is 1000, 0.1 with 2 decimals is 10
    txid = send(int(row['assetId']), int(float(row['quantity']) * 100), row['to'], row['note'])
    transactions.append(txid)

# Now we've sent everything, just wait until we can confirm all have been sent through
for txid in transactions:
    confirm_sent(txid)
    print(txid, 'sent')
```

    {'assetId': '52057232', 'quantity': '50', 'to': 'DEMOIQZCE6HX2GMEXPGP3O3QZPMIVHAALJE6LNBVF2ACHIMAITRUFJOQ5M', 'note': None}
    {'assetId': '52057232', 'quantity': '42', 'to': 'DEMOUN4WTPLYTK347QENBTB7BOPJKTA5LIYRR55NIEDLIZRW3IFUV66TGU', 'note': ' A note'}
    {'assetId': '52057232', 'quantity': '.1', 'to': 'DEMO5BFQEZGQRMAV7DB3ZKGFZC32OO5QKMNJKMRS52PRQ5LCPV7GKKGDWQ', 'note': None}
    FZWRS7H4OPDEJOXTFMSW5ONOWCJDEL4OM7G7VOKLY6BTNR26UAXQ sent
    GBFZ56QBDQLKCMJME2FHHG2U4I7YTSL5LGHGO6DVTJWFVX5OYNKQ sent
    CAYRDMJAX66KO5TE6YPQEJYFVKDG7UDS33FBDPS4HAJLRPUEPHJQ sent



```python

```
