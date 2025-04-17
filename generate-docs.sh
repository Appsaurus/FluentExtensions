#!/bin/bash
swift package \
--allow-writing-to-directory ./docs \
generate-documentation \
--target FluentExtensions \
--output-path ./docs \
--transform-for-static-hosting \
--hosting-base-path FluentExtensions \
--enable-inherited-docs \
--emit-hosting-base-path \
--disable-indexing false
