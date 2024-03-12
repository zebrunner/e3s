# E3S

Zebrunner Elastic Executor Engine Service

Scalable CI/CD implementation for automating any kind of workflows including
 * [Zebrunner Selenium Grid](https://zebrunner.com/selenium-grid)
 * [Zebrunner CyServer](https://zebrunner.com/cyserver)
 * Generic CI/CD automation

## Features

### Ready to use Browser Images
No need to manually install browsers or dive into WebDriver documentation.
New images are added right after official releases.

### Video Recording
* Any browser session can be saved to [H.264](https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC) video ([example](https://www.youtube.com/watch?v=maB298oO5cI))
* An API to list, download and delete recorded video files

### Convenient Logging

* Any browser session logs are automatically saved to files - one per session
* An API to list, download and delete saved log files

### Lightweight and Lightning Fast
Suitable for personal usage and in big clusters:
* Consumes **10 times** less memory than Java-based Selenium server under the same load
* **Small 6 Mb binary** with no external dependencies (no need to install Java)
* **Browser consumption API** working out of the box
* Fully **isolated** and **reproducible** environment

## Documentation 
* [Installation](docs/installation.md)
* [Capabilities](docs/capabilities.md)
* [Errors](docs/errors.md)
