> [matryx.ai](https://www.matryx.ai): A Collaborative Research and Development Platform

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

3. The following commands are all executing inside truffle console
    ```
    migrate --reset
    .load setup
    ```


---
-The Matryx Team
