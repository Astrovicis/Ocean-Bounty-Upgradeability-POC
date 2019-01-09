## Performing An Upgrade

1. Install dependencies, remove the build folder, and start ganache
    ```
    npm i
    rm -r build/
    ./ganache-local.sh
    ```

2. Then in a new window, enter the truffle console
    ```
    truffle console
    ```

3. The following commands are executed inside of truffle console
    ```
    migrate --reset
    .load setup
    ```
    
 4. You may now perform DIDRegistry functions as you would on a normal smart contract.
     ```
     registry = contract(DIDRegistry.address, IDIDRegistry)
     registry...(TBC)
     ```
     
  5. 
