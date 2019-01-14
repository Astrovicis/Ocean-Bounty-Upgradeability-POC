## Performing An Upgrade

1. Install dependencies, remove the build folder, and start ganache
    ```
    npm i
    rm -r build/
    ./ganache-local.sh
    ```

2. In a new window, enter truffle console
    ```
    truffle console
    ```

3. Execute the following in truffle console
    ```
    migrate --reset
    .load setup
    ```
    
 4. You may now perform DIDRegistry functions as you would on a normal smart contract.
     ```
        registry.registerAttribute(stb('did'), 2, stb('key'), 'value')
        registry.getOwner(stb('did'))
     ```
     You will notice that the owner has been set to your first account.
     
  5. Perform the storage upgrade
    ```
        .load upgrade
        registry.getOwner(stb('did'))
        storage.getInfo()
    ```
    Notice that owner has changed to ContractSystem's address,
    and that the storage version has been incremented to 2!
    You've just performed a storage upgrade. Pretty cool, eh?
