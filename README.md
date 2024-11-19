# SGR-Erc20-Token

## Security Improvements:
  - Added blacklist function to restrict transfers to malicious addresses
  - Add an emergency withdrawal function in case the contract receives an unexpected ETH transfer

## Traceability improvement:
  - Added token destruction event tracking
  - Add more event logs for easy tracking of mints and quota changes
  - Improve event logs to facilitate subsequent audit and monitoring

## Functional Improvements:
  - Added a token lock mechanism that can limit transfers to specific addresses for a certain period of time
  - Add bulk transfer capabilities to improve efficiency and save gas
  - Added a token recovery function to increase control in case of emergency

## Rights Management Improvements:
  - Added a minting authority delegation mechanism that allows the owner to specify other addresses with minting authority
  - Improve the authority check mechanism

## Follow up consideration:
  - Added token upgrade mechanism
  - Added vote weight function
  - Added bonus mechanism
  - Added a token repurchase destruction mechanism
