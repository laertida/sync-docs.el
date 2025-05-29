# sync-docs.el

> Seamlessly publish your Emacs org-mode documentation to Atlassian Confluence!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Emacs](https://img.shields.io/badge/emacs-29.1%2B-blue.svg)](https://www.gnu.org/software/emacs/)

## Overview

**sync-docs.el** is an Emacs helper package that lets you effortlessly publish your org-mode files to Confluence spaces. It converts org documents to HTML, handles attachments (like images), and pushes your content to Confluence via its REST API—right from Emacs.

- **Write in org-mode, publish to Confluence.**
- **Handles images and attachments automatically.**
- **Supports updating existing pages or creating new ones.**
- **Customizable for your Confluence space, credentials, and workflow.**

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [How it Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- Export org-mode buffers to HTML, extract only the body contents.
- Authenticate with Confluence using username and API token.
- Create and update Confluence pages in a specified space and parent.
- Upload and update image attachments referenced in your org file.
- Customizable via Emacs `defcustom` variables.
- Interactive commands for publishing and versioning documentation.

## Installation

### Requirements

- **Emacs 29.1+**
- [org-mode](https://orgmode.org/) (builtin)
- [request.el](https://github.com/tkf/emacs-request)
- Access to an Atlassian Confluence instance (Cloud or Server with REST API)

### Using `straight.el` or `use-package`

```elisp
(use-package sync-docs
  :load-path "path/to/sync-docs.el")
```

Or just place `sync-docs.el` in your `load-path` and `(require 'sync-docs)`.

## Configuration

Customize the following variables, either via `M-x customize-group RET sync-docs RET` or in your Emacs config:

```elisp
(setq sync-docs-host "https://your-confluence-instance")
(setq sync-docs-user "your.email@example.com")
(setq sync-docs-token "your-api-token")
(setq sync-docs-space-id "SPACEKEY")
(setq sync-docs-default-parent-id "123456") ;; Confluence parent page ID
```

## Usage

Open an org-mode file you want to publish, then run:

```
M-x sync-docs
```

You’ll be prompted for:
- Status: `draft` or `current`
- Message: Comment for this version
- Whether to update images: `yes` or `no`

### What happens:

- The org file is exported to HTML.
- Page is created or updated in Confluence (under the configured space/parent).
- Images referenced as file/attachment links are uploaded and converted for Confluence display.
- Version and sync metadata is tracked in org properties.

## How it Works

- **Authentication:** Uses HTTP Basic Auth with your email and API token.
- **HTML Export:** Converts buffer to HTML and extracts the body for Confluence's storage format.
- **Page Creation/Update:** Calls Confluence REST API to publish the content (handles versioning).
- **Images:** Uses `curl` under the hood to upload local images as attachments.
- **Properties:** Stores sync IDs and version numbers in org properties for incremental publishing.

## Troubleshooting

- Ensure your Confluence user has permission to create/edit pages and upload attachments in the specified space.
- The API token must be valid for your Confluence instance.
- Check network connectivity and REST API availability.
- Debug output is available in the Emacs `*Messages*` buffer.

## Contributing

Contributions are welcome! Please open issues or pull requests.

## License

This project is licensed under the terms of the GNU General Public License v2.0 only.  
See the [LICENSE](LICENSE) file for details.
