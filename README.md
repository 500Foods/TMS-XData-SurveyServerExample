# TMS-XData-SurveyServerExample
 Example of TMS XData server as REST API for survey example
 
## Usage Note: RandomDLL.DLL
This DLL needs to be included in the same folder as the project executable. It is needed by the SHA-256 hash function that is used in several places, that, in turn, comes from the [TMS Cryptography Pack](https://www.tmssoftware.com/site/tmscrypto.asp). A post-build event has been added to the project to do this automatically.  This assumes that a Win64 project is being built.  Please adjust accordingly.

## Key Dependencies
As with any modern application, other libraries/dependencies have been used in this project.
- [TMS XData](https://www.tmssoftware.com/site/tmswebcore.asp) - This is a TMS XData project, after all
- [TMS Cryptography Pack](https://www.tmssoftware.com/site/tmscrypto.asp) - Supples the SHA-256 hash function

## Sponsor / Donate / Support
If you find this work interesting, helpful, or useful, or that it has sved you time, money, or both, please consider direclty supporting these efforts financially via [GitHub Sponsors](https://github.com/sponsors/500Foods) or donating via [Buy Me a Pizza](https://www.buymeacoffee.com/andrewsimard500). Also, be sure to check out these other [GitHub Repositories](https://github.com/500Foods?tab=repositories&q=&sort=stargazers) that may be of interest to you.
