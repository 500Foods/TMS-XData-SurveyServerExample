# TMS-XData-SurveyServerExample
This is a component of the [TMS WEB Core](https://www.tmssoftware.com/site/tmswebcore.asp) (Delphi web app) and [TMS XData](https://www.tmssoftware.com/site/xdata.asp) (Delphi REST API) project that implements a complete web-based survey app. The complete set includes the following.

1. [Survey Server Example](https://github.com/500Foods/TMS-XData-SurveyServerExample) (REST API implemented with TMS XData)
2. [Survey Admin Client](https://github.com/500Foods/TMS-Web-Core-SurveyAdminClient) (web app implemented with TMS WEB Core)
3. [Survey Client Example](https://github.com/500Foods/TMS-WEB-Core-SurveyClientExample) (web app implemented with TMS WEB Core)

The project first appeared as a mini-series on the [TMS Software Blog](https://www.tmssoftware.com/site/blog.asp). The first of the three parts is available [here](https://www.tmssoftware.com/site/tmswebcore.asp).
 
## Usage Note: RandomDLL.DLL
This DLL needs to be included in the same folder as the project executable. It is needed by the SHA-256 hash function that is used in several places, that, in turn, comes from the [TMS Cryptography Pack](https://www.tmssoftware.com/site/tmscrypto.asp). A post-build event has been added to the project to do this automatically.  This assumes that a Win64 project is being built.  Please adjust accordingly.

## Key Dependencies
As with any modern application, other libraries/dependencies have been used in this project.
- [TMS XData](https://www.tmssoftware.com/site/tmswebcore.asp) - This is a TMS XData project, after all
- [TMS Cryptography Pack](https://www.tmssoftware.com/site/tmscrypto.asp) - Supples the SHA-256 hash function

## Repository Information
[![Count Lines of Code](https://github.com/500Foods/TMS-XData-SurveyServerExample/actions/workflows/main.yml/badge.svg)](https://github.com/500Foods/TMS-XData-SurveyServerExample/actions/workflows/main.yml)
```
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Pascal                           9           1556           3791          10609
Delphi Form                      3              1              0            123
YAML                             2              4              8             15
Markdown                         1              3              0             10
-------------------------------------------------------------------------------
SUM:                            15           1564           3799          10757
-------------------------------------------------------------------------------
```

## Sponsor / Donate / Support
If you find this work interesting, helpful, or valuable, or that it has saved you time, money, or both, please consider directly supporting these efforts financially via [GitHub Sponsors](https://github.com/sponsors/500Foods) or donating via [Buy Me a Pizza](https://www.buymeacoffee.com/andrewsimard500). Also, check out these other [GitHub Repositories](https://github.com/500Foods?tab=repositories&q=&sort=stargazers) that may interest you.
