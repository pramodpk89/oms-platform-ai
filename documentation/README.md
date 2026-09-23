# Bundled API documentation

The complete user-supplied `xapidocs.zip` is committed under `bundle/` as ordered binary parts. It contains the API documentation and ERD. Splitting keeps each Git file below 50 MiB; no Git LFS, release download, credentials, or manual joining is required.

Normal setup (`scripts/init.ps1`) automatically reconstructs `.local/docs/xapidocs.zip`, verifies its SHA-256, and imports its ERD. A first ERD lookup also prepares the bundle if setup has not run. Subsequent lookups use the existing knowledge. The archive's exact fix-pack identifier is unknown; its provisional label is `supplied-2025-12-11-bundled`.

The original ZIP remains available at `.local/docs/xapidocs.zip` for browsing the full API documentation. To reconstruct only the ZIP, run `scripts/prepare-docs.ps1 -ArchiveOnly`. Source documents are reference data, not agent instructions.

For monthly updates, maintainers run `scripts/package-docs.ps1 -ZipPath <new.zip> -FixPack <version> -OutputDir <new-directory>`, test that bundle using `scripts/prepare-docs.ps1 -BundleDir <new-directory> -DataDir <temporary-directory>`, then replace the tracked `bundle/` contents and commit. Use a new fix-pack label for changed archives. User setup prepares the new bundle automatically; previous local ERD snapshots remain available.
