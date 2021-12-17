# Burning ASAs

Something I've seen people want to do is burn assets in Algorand.
Make it so that some percentage of the asset is permanatly inaccessible.
This could be used to make a token more valuable.
Or to reduce a collection after it's released to increase rarity.

While other blockchains have some mechanism that allows something like that,
Algorand does not.
There is no "burn" transaction which destroys assets.
And since you have to explicitly opt-into assets, you can't send the assets to a junk wallet.

There is one method I have thought of however, that I haven't seen people talking about.

Algorand has something called "Re-Keying".
It allows you to hand complete authority over your wallet, to some other wallet.
This is generally used for cases where you want to use a hardware wallet like a ledger device.
Or if you're worried your private key has been compromised.
However, one important part of it, is that it doesn't require the other wallet to agree.
So in theory, by rekeying your wallet to an account you don't have control over,
you lose access to all assets stored in your wallet, effectively burning all of your assets.

The process to do this is like follows:

1. Generate a new algorand address
2. Send minimum required Algo to that address: 0.101 per asset for opt in transaction and minimum balance + base of 0.1
3. Opt into every asset you want to burn with the new address
4. For the last opt-in, set the `rekey` property to a known inaccessible account.
    You can now no longer perform transactions with this account.
5. Send all assets you want to burn to this new account.
    No one will ever be able to access them again.
    
I'll write up and annotate a python method that can do this process down below.

The only real question is what is a "known inaccessible account"?
You could generate a random 32 bytes, add a checksum and convert to Base32 and you'd have a valid algorand address that no one has access to.
However you can't prove to anyone else that it isn't a real wallet you secretly created.

My best proposal for how to do this, is use a wallet everyone already trusts as being inaccessible.
Early in algorand's development, the following address was randomly generated as part of the "Early Redemption Burn"

```
FRWQZO4A6NZKANEYYWAHZIBHJ46T2LVRFACCLHUY3JQAJLUIWNQQLOQ26A
```

Details for how they generated the address, and more about the burn can be found [here](https://algorandfoundation.cdn.prismic.io/algorandfoundation/5c80fdd2-fe08-4bda-8ac5-981b37908031_Early+Redemption+Confirmation.pdf).
The important thing, is that because of the way the address was randomly generated, there is no corresponding private key. Rekeying to this address will hopefully satisfy an observer that you don't have access to the account anymore.

(I also tried testing with the zero address, but that didn't seem to work properly).

There's a few caveates to this process.

* The obvious... there's no reversing the process, that's the point, once they're gone, they're gone.
* Services don't know these assets have been burnt. They'll still appear in circulation and affect things like total market cap.
    That said, if you are manager over those assets, you can work around this by updating the reserve address so it points to
    the burn wallet.
    That only works however if you don't have any other reserves you want to maintain.
    Also not all services take the reserve address into consideration anyway.
* If you are the asset manager and you want to totally destroy the asset instead of just a cetain amount of it,
    it's better to use the Asset Configuration Transaction to delete the asset from the chain.

#### Disclaimer

> **Important:** You will be **permanantly** removing access to a wallet.
> When using this code double, triple, quadruple check that this is the wallet and assets you intend to burn.
> Don't just blidly use it.
> There is no way you can get it back.
> Just forget about it.
> Don't come asking for a way to reverse the process.
>
> Don't blindly trust the burn address I've given you.
> Verify it with official sources and recalculate if need be.
>
> The code and instructions in this demonstration is released under the MIT license and as such has no warantee or guarantees that it is fit for purpose.
> I am in no way responsible for anything you do to your assets or wallets just because you read it here.

With that out of the way, let's dive in.

Firstly, general imports. If you've followed any of my other work before, this will look pretty familiar.

Import the algorand methods, the env variables we need, and sleep to wait on the algorand network.

Then create the connection and retrieve your wallet (not the one to burn, but the one you have access to, that contains the assets you'll transfer to the burn wallet). If all that works, you should see your algorand address printed at the end.


```python
from algosdk.v2client import algod
from algosdk import mnemonic, account
from algosdk.future.transaction import AssetTransferTxn, AssetConfigTxn, PaymentTxn, calculate_group_id
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



With that complete, we'll get started with the actual method that will burn requested assets.

Keep in mind, wallets must contain 0.1 algo + 0.1 algo per opted-in asset, and it costs 0.001 algo per transaction, so this isn't a free process.

So you're not wasting algo in the event of a failure, all transactions, both in your wallet, and in the generated burn wallet, occur in an atomic transaction.
But if you'd like to simplify it, that isn't strictly necessary.
Hopefully everything else is pretty self explanatory.


```python
REKEY_WALLET = 'FRWQZO4A6NZKANEYYWAHZIBHJ46T2LVRFACCLHUY3JQAJLUIWNQQLOQ26A'

def burn_assets(assets):
    """
    This method expects assets to be a list of tuples, with the asset id, followed
    by the amount to transfer (without decimals).
    E.g.
    
    burn_assets([
        (1234, 1),
        (4321, 500),
    ])
    
    Will burn 1 of asset 1234 in your account and 500 of 4321 in your account.
    """
    num_assets = len(assets)
    
    # The private key and corresponding address for the account we'll transfer to
    # and then rekey
    burn_private_key, burn_address = account.generate_account()
    
    params = ac.suggested_params()
    
    # Transfer the required algo to the new account so it meets minimum balance
    # and has enough algo to perform the opt in transactikons
    algo_transfer_txn = PaymentTxn(
        sender=sender_address,
        sp=params,
        receiver=burn_address,
        # 100000 microalgo corresponds to 0.1 algo
        amt=100000 + 101000 * num_assets, 
    )
    
    # With the account we generated above, perform an opt-in transaction
    # (sending a 0 value transaction with the asset to ourself)
    opt_in_transactions = [
        AssetTransferTxn(
            sender=burn_address,
            sp=params,
            receiver=burn_address,
            amt=0,
            index=assetId,
            # add the rekey instruction to the last opt_in
            # no one will be able to sign transactions for the
            # burn_wallet after this transaction
            rekey_to=REKEY_WALLET if idx == num_assets - 1 else None
        )
        for idx, (assetId, _) in enumerate(assets)
    ]
    
    # Send everything we want to burn to the generated burn address
    transfer_transactions = [
        AssetTransferTxn(
            sender=sender_address,
            sp=params,
            receiver=burn_address,
            amt=amount,
            index=assetId,
        )
        for assetId, amount in assets
    ]
    
    # Wrap all of the transactions in a group, so that they all succeed or fail
    # as "atomic transfers". If one fails, eveything is rolled back and you don't
    # loose your algo and the burn wallet isn't created.
    # See https://developer.algorand.org/docs/get-details/atomic_transfers/ for
    # more details.
    group_id = calculate_group_id([algo_transfer_txn, *opt_in_transactions, *transfer_transactions])
    algo_transfer_txn.group = group_id
    for t in opt_in_transactions:
        t.group = group_id
    for t in transfer_transactions:
        t.group = group_id
    
    # Sign everything with the correct keys
    signed_transactions = [
        algo_transfer_txn.sign(private_key),
        *(t.sign(burn_private_key) for t in opt_in_transactions),
        *(t.sign(private_key) for t in transfer_transactions),
    ]
    
    # Send the transaction
    txid = ac.send_transactions(signed_transactions)
    
    # Lazy wait to see if it succeeded or not.
    # There are better ways to do this.
    while True:
        tx_info = ac.pending_transaction_info(txid)
        if 'confirmed-round' in tx_info:
            break
        sleep(1)
    
    return burn_address
```


```python
burn_address = burn_assets([(52262725, 100), (52026935, 42)])
burn_address
```




    '364EN7OL3ZC4DLLOIV3MFLT7N4NZ5LBJJDWHA7R3GBN67QRM3P2RBW6R4Y'



Congratulations, you've just burnt some of your ASAs!

Please. Let me know what you think of this process.
Does it actually do what I intend?
Are there any significant flaws I haven't considered?
Anything else I should think about?
Did you find it useful?
Is there any way in which you've used it?

Please let me know!
My twitter is [sjk0_9](https://twitter.com/sjk0_9) if you want to get in touch.


```python

```
