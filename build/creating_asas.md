# Creating ASAs and NFTs

Here we'll create some quick, helpful functions to create and manage our own ASAs.
These could be used for a whole range of things, including (but not limited to) NFTs.

We'll also cover how to upload and pin to the IPFS via Pinata and how to include [ARC-69](https://github.com/algokittens/arc69) metadata when creating your assets.

By the end of this you should be able to start building your own tools for creating and managing ASAs and NFTs.

To begin, we'll import the required algorand methods as well as our environment we set up [here](./env_file.md), requests (which we'll use to connect to Pinata), hashlib for creating the hash of our file, json for ARC-69 and the sleep method for waiting on the algorand network.

We'll then create the algorand connections we need, and get the key and address from our mnemonic. If all works, you should see your algorand address printed at the end.


```python
from algosdk.v2client import algod
from algosdk import mnemonic, account
from algosdk.future.transaction import AssetConfigTxn
import env
import requests
import hashlib
import json
from time import sleep
```


```python
ac = algod.AlgodClient(env.API_TOKEN, env.ALGOD_ADDRESS, env.API_HEADERS)
private_key = mnemonic.to_private_key(env.MY_PHRASE)
sender_address = account.address_from_private_key(private_key)
sender_address
```




    'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ'



The algorand network accepts 6 different types of transactions.
You've probably used `pay` (the payment transaction for sending algo) and `axfer` (the asset transfer transaction for sending any other kind of asset).
To create an manage our assets, we're going to use a transaction called `acfg`.
The Asset Configuration Transaction.

Fortunately the python library makes this really simple.

Let's create our own function, to create an asset


```python
def create_asset(total, decimals, **kwargs):
    arguments = {
        "sender": sender_address,
        # These are just some default details that the transaction requires
        "sp": ac.suggested_params(),
        # Total is the number of divisible units
        # Decimals is the number of decimal places
        # For instance, if total is 100 and decimal is 1
        # Then you'd have 10.0 assets.
        "total": total,
        "decimals": decimals,
        # When DefaultFrozen is true, holders won't be able to transfer
        # the asset out of their wallet without them being unfrozen first
        "default_frozen": False,
        # These are who has the ability to do certain things with the asset
        # Often you want them to be the creator of the asset
        # But in many cases, you probably want at least freeze and clawback
        # to be "" so your holders can be confident you won't mess with their
        # collection.
        "manager": sender_address,
        "reserve": sender_address,
        "freeze": sender_address,
        "clawback": sender_address,
        # This is just protection to make sure you don't accidentally unset
        # any of the above properties, locking out access
        "strict_empty_address_check": False,
        # We can override any settings, or provide those we haven't used yet
        # by using kwargs when calling the method.
        # E.g. create_asset(1, 0, asset_name="My Cool NFT", freeze="", clawback="")
        **kwargs
    }
    # Actual config transaciton
    txn = AssetConfigTxn(**arguments)
    # Sign it, so the blockchain is confident we're the ones who sent it
    signed_txn = txn.sign(private_key)
    # Send it! Create the asset!
    txid = ac.send_transaction(signed_txn)
    return txid
```


```python
create_txid = create_asset(10000000, 2, asset_name="My Cool ASA", freeze="", clawback="")
create_txid
```




    'N7NT4HANGQ5O5OZRNIQ5KWQAROTCXV2GSS5M2KIYRRJBU6REZTEA'



Now we've got the transaction that's been used to create our asset, but we don't have
the asset itself.
Lets create another method that can find a created asset using the indexer.


```python
def find_asset_from_create_tx(txid):
    # First, wait until our transaction has been confirmed
    while True:
        tx_info = ac.pending_transaction_info(txid)
        if 'confirmed-round' in tx_info:
            break
        sleep(1)

    assetId = tx_info['asset-index']
    
    return ac.asset_info(assetId)
```


```python
find_asset_from_create_tx(create_txid)
```




    {'index': 52057232,
     'params': {'creator': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'decimals': 2,
      'default-frozen': False,
      'manager': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'name': 'My Cool ASA',
      'name-b64': 'TXkgQ29vbCBBU0E=',
      'reserve': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'total': 10000000}}



## Creating NFTs

Now we've got some helpful tools for creating our ASAs,
it becomes pretty trivial to use them for creating an NFT.
Just set the `url` and the optional `metadata_hash` to point to the file you want to track.

> A quick note about `metadata_hash`. I've seen a lot of people (myself included) use the content identifier from the IPFS URI as the `metadata_hash` but, [they're two different things](https://docs.ipfs.io/concepts/hashing/#content-identifiers-are-not-file-hashes).
>
> The file hash should be determined by hashing the file itself, using something like python's `hashlib` library. We'll do that here to demonstrate.

Lets say we want to create an NFT out of this ground breaking piece of digital media.
A black pixel:

![A black pixel](../a-black-pixel.png)

For now, I've manually uploaded it to pinata, but we'll go through automating the upload later.
It's located at:

```
ipfs://QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1
```

We'll also ignore the hash for now, cause we'll automate it later too.

To create an NFT, we just have to create the asset as before and assign the URL:


```python
create_txid = create_asset(
    total=1,
    decimals=0,
    asset_name="My Cool NFT",
    freeze="",
    clawback="", 
    url="ipfs://QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1"
)
my_cool_nft = find_asset_from_create_tx(create_txid)
my_cool_nft
```




    {'index': 52057243,
     'params': {'creator': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'decimals': 0,
      'default-frozen': False,
      'manager': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'name': 'My Cool NFT',
      'name-b64': 'TXkgQ29vbCBORlQ=',
      'reserve': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'total': 1,
      'url': 'ipfs://QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1',
      'url-b64': 'aXBmczovL1FtVkdzOU1aeHE0c2gzYm9USndxclprTkE2dWhXWkJjdGhiRUFjMmQ1RzM3ZzE='}}



Easy as that.

### Automating upload and metadata-hash

Now, lets also handle uploading the NFT, and creating some hash_metadata for it.


```python
def upload_to_pinata(file):
    url = 'https://api.pinata.cloud/pinning/pinFileToIPFS'
    # open the file in binary read mode, otherwise we might get some weird
    # behaviour with requests
    with open(file, 'rb') as f:
        # Send it to the endpoint... simple as that. Requests makes this really
        # easy.
        r = requests.post(
            url,
            files={'file': f},
            headers={'Authorization': f"Bearer {env.PINATA_JWT}"}
        )
        
    # If something went wrong, raise an error, otherwise just return the data
    # we want
    r.raise_for_status()
    return r.json()
```


```python
def get_hash(file):
    m = hashlib.sha256()
    # Read the file in a bit at a time, adding each to the hash:
    with open(file, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            m.update(chunk)
    # Actually compile the hash and return it in bytes format
    return m.digest()
```

And so it's now just simply a matter of passing that file to these methods and adding the return to our Asset Management Transaction.


```python
pin = upload_to_pinata('../a-black-pixel.png')
pin['IpfsHash']
# Note, it's the same as above, because IPFS recognises it as a duplicate
```




    'QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1'




```python
file_hash = get_hash('../a-black-pixel.png')
file_hash
```




    b' \xc5\xe1\x97\x1a\xdb|\x12\xbf\xf3\xd1%\xc2y\xf8FRd\xc8A\x81\xc6\xea\xda\xcd\xd5\xf6\xfb\x96[\xb6s'




```python
create_txid = create_asset(
    total=1,
    decimals=0,
    asset_name="My Cool Automated NFT",
    freeze="",
    clawback="", 
    url=f"ipfs://{pin['IpfsHash']}",
    metadata_hash=file_hash
)
my_cool_automated_nft = find_asset_from_create_tx(create_txid)
my_cool_automated_nft
```




    {'index': 52057274,
     'params': {'creator': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'decimals': 0,
      'default-frozen': False,
      'manager': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'metadata-hash': 'IMXhlxrbfBK/89Elwnn4RlJkyEGBxurazdX2+5ZbtnM=',
      'name': 'My Cool Automated NFT',
      'name-b64': 'TXkgQ29vbCBBdXRvbWF0ZWQgTkZU',
      'reserve': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'total': 1,
      'url': 'ipfs://QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1',
      'url-b64': 'aXBmczovL1FtVkdzOU1aeHE0c2gzYm9USndxclprTkE2dWhXWkJjdGhiRUFjMmQ1RzM3ZzE='}}



## ARC-69

[ARC-69](https://github.com/algokittens/arc69) is a proposal by [AlgoKittens](https://github.com/algokittens) to track metadata along with your NFTs.
It's supported in a range of places, including Rand Gallery, where you can see an NFT's "Attributes" or "Traits".

The general summary is that you append the metadata to the notes field of an Asset Configuration Transaction. As such, you can add the metadata at creation, or update it later, as long as you still have the `manager` property set on the asset.

The metadata is stored in the json format, which may look something like this:

```json
{   
  "standard": "arc69",
  "description": "An NFT we created as a demo",
  "media_url": "ipfs://QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1",
  "external_url": "https://github.com/sjk0-9",
  "mime_type":"image/png",
  "attributes": [
    {
      "trait_type": "Color",
      "value": "Black"
    },
    {
      "trait_type": "Size",
      "value": "Smallest"
    },
    {
      "trait_type": "Rarity",
      "value": 100
    }
  ]
}
```

Since we can apply this to previous assets we've made, lets create a new method that lets us update our assets to apply the metadata.


```python
def update_asset(assetId, **kwargs):
    # More or less same as above, though we need to add the assetId we're updating.
    arguments = {
        "index": assetId,
        "sender": sender_address,
        # These are just some default details that the transaction requires
        "sp": ac.suggested_params(),
        # If we don't send these through, that's actually a delete command.
        # It's ok if you've unset any fields, you can't overwrite those
        "manager": sender_address,
        "reserve": sender_address,
        "freeze": sender_address,
        "clawback": sender_address,
        **kwargs
    }
    # Actual config transaciton
    txn = AssetConfigTxn(**arguments)
    # Sign it, so the blockchain is confident we're the ones who sent it
    signed_txn = txn.sign(private_key)
    # Send it! Update the asset!
    txid = ac.send_transaction(signed_txn)
    return txid
```


```python
update_asset(my_cool_automated_nft['index'], note='Hello World!')
```




    'F7LCSASDXEFKYWJSEPS2SAV3ERLGBHWFUS7AKIMBGNNMZR6VJY6A'



If you take a look at that in algoexplorer, you'll see the transaction with the note attached.
Let's make the note actually fulfill the ARC69 requirements though


```python
def create_arc69_note(
    description=None, external_url=None, media_url=None, mime_type=None, attributes=None
):
    body = {
        "standard": 'arc69',
        "description": description,
        "external_url": external_url,
        "media_url": media_url,
        "mime_type": mime_type,
        "attributes": attributes
    }
    # Removes all the fields without any data in them
    clean_body = {k: v for k, v in body.items() if v is not None}
    # Write to a json, byte string.
    # Specify the separators without spaces in them, so we save on
    # storage space. You've only got 1000 bytes to work with.
    return json.dumps(clean_body, separators=[",", ":"]).encode()

# Just a simple helper to format attributes without having to type
# the whole thing out over and over
def arc69_attr(trait_type=None, value=None, **kwargs):
    body = { "trait_type": trait_type, "value": value, **kwargs }
    clean_body = {k: v for k, v in body.items() if v is not None}
    return clean_body
```


```python
arc69_metadata = create_arc69_note(
    description='An NFT we created as a demo',
    media_url="ipfs://QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1",
    external_url="https://github.com/sjk0-9",
    mime_type="image/png",
    attributes=[
        arc69_attr('Color', 'Grey'),
        arc69_attr('Size', 'Smallest'),
        arc69_attr('Rarity', 100)
    ]
)
arc69_metadata
```




    b'{"standard":"arc69","description":"An NFT we created as a demo","external_url":"https://github.com/sjk0-9","media_url":"ipfs://QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1","mime_type":"image/png","attributes":[{"trait_type":"Color","value":"Grey"},{"trait_type":"Size","value":"Smallest"},{"trait_type":"Rarity","value":100}]}'



And so with this, we can either create a new asset and put the metadata in the note:


```python
create_txid = create_asset(
    total=1,
    decimals=0,
    asset_name="My Cool ARC-69 NFT",
    freeze="",
    clawback="", 
    url=f"ipfs://{pin['IpfsHash']}",
    metadata_hash=file_hash,
    note=arc69_metadata
)
my_cool_arc69_nft = find_asset_from_create_tx(create_txid)
my_cool_arc69_nft
```




    {'index': 52057325,
     'params': {'creator': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'decimals': 0,
      'default-frozen': False,
      'manager': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'metadata-hash': 'IMXhlxrbfBK/89Elwnn4RlJkyEGBxurazdX2+5ZbtnM=',
      'name': 'My Cool ARC-69 NFT',
      'name-b64': 'TXkgQ29vbCBBUkMtNjkgTkZU',
      'reserve': 'DEMOAOT4WHSF7RHA7ICKIHJGXPSVGH5AFMTRJFSUTVBEYZ6Y2EV2K3XCVQ',
      'total': 1,
      'url': 'ipfs://QmVGs9MZxq4sh3boTJwqrZkNA6uhWZBcthbEAc2d5G37g1',
      'url-b64': 'aXBmczovL1FtVkdzOU1aeHE0c2gzYm9USndxclprTkE2dWhXWkJjdGhiRUFjMmQ1RzM3ZzE='}}



Or add it to an existing asset: 


```python
update_asset(my_cool_automated_nft['index'], note=arc69_metadata)
```




    'PZYNNUM5ZIMXGOULLDN3YHVAQW7YZLNXPJOSHOPK2FBYAW2TJ4UQ'



## Congratulations!

If you've been able to follow along with this guide, you should have everything you need to start programatically creating and publishing your own NFTs.

I'd love to see what you've created with this.
Feel free to get in touch, my twitter is [sjk0_9](https://twitter.com/sjk0_9).

If you've got any feedback or improvements, please let me know!


```python

```
