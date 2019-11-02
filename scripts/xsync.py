#! /usr/bin/env python
# -*- coding: UTF-8 -*-

# *****************************************************************************
#  META INFORMATION
# *****************************************************************************

__all__ = ["sync"]

__program__ = "xsync"
__version__ = "0.9.1 alpha"


# *****************************************************************************
#  MODULE IMPORTATION
# *****************************************************************************

import sys
import os
import shutil
import hashlib
from optparse import OptionParser


# *****************************************************************************
#  VARIABLE DECLARATION
# *****************************************************************************


# *****************************************************************************
#  FUNCTION DEFINITION
# *****************************************************************************

# md5_file
def md5_file(file):
    """
        Calculate the MD5 digest of the file
        result presents in lower case
    """

    if not os.path.isfile(file):
        raise Exception("File not exist")

    fd = open(file, "rb")
    hash = hashlib.md5()

    while True:
        buffer = fd.read(4096)

        if not buffer:
            break

        hash.update(buffer)

    fd.close()

    return hash.digest().lower()


# diff_by_size
def diff_by_size(file1, file2):
    """
        Diff 2 files by size
    """

    file1_size = int(os.stat(file1).st_size)
    file2_size = int(os.stat(file2).st_size)

    return (file1_size == file2_size)


# diff_by_hash
def diff_by_hash(file1, file2):
    """
        Diff 2 files by hash
    """

    file1_hash = md5_file(file1)
    file2_hash = md5_file(file2)

    return (file1_hash == file2_hash)


# sync
def sync(source, target, diff_func = diff_by_size, overwrite = True, preserve_time = False, dry_run = False):
    """
        Synchronize target directory with source directory
        (Currently overwrite, preserve_time and dry_run are not available)
    """

    source = source.rstrip(os.sep) + os.sep
    target = target.rstrip(os.sep) + os.sep
    base_length = len(source)

    for (path, dirs, files) in os.walk(source):
        path = path.rstrip(os.sep) + os.sep
        relative_path = path[base_length:].rstrip(os.sep) + os.sep
        target_prefix = target + relative_path

        if os.path.isfile(target_prefix):
            os.unlink(target_prefix)
            sys.stdout.write("Removed\t %s\n" % relative_path.lstrip(os.sep))

        if not os.path.isdir(target_prefix):
            os.mkdir(target_prefix)
            shutil.copymode(path, target_prefix)
            sys.stdout.write("Created\t %s\n" % relative_path.lstrip(os.sep))

        for existed in os.listdir(target_prefix):
            if existed in dirs or existed in files:
                continue

            existed_path = target_prefix + existed

            if os.path.isfile(existed_path):
                os.unlink(existed_path)

            elif os.path.isdir(existed_path):
                shutil.rmtree(existed_path)

            sys.stdout.write("Cleaned\t %s\n" % (relative_path + existed).lstrip(os.sep))

        if len(files) == 0:
            continue

        for filename in files:
            source_file = path + filename
            target_file = target_prefix + filename

            if os.path.isfile(target_file) and diff_func(source_file, target_file):
                continue

            if os.path.isfile(target_file):
                os.unlink(target_file)
                sys.stdout.write("Removed\t %s\n" % (relative_path + filename).lstrip(os.sep))

            elif os.path.isdir(target_file):
                shutil.rmtree(target_file)
                sys.stdout.write("Removed\t %s\n" % (relative_path + filename).lstrip(os.sep))

            shutil.copy(source_file, target_file)

            sys.stdout.write("Synced\t %s\n" % (relative_path + filename).lstrip(os.sep))

    return True


# *****************************************************************************
#  CLASS DEFINITION
# *****************************************************************************


# *****************************************************************************
#  MAIN PROGRAM ENTRY
# *****************************************************************************

if __name__ == "__main__":
    # entry
    usage = "Usage: %prog [OPTIONS] SOURCE TARGET"
    parser = OptionParser(usage=usage)
    #parser.add_option("-n", "--dry-run", dest="dry_run", action="store_true", default=True, help="Show actions only (default off)")
    #parser.add_option("-f", "--force", dest="overwrite", action="store_true", default=True, help="Overwrite existed files (default on)")
    parser.add_option("-c", "--checksum", dest="checksum", action="store_true", default=False, help="Use checksum to verify files to be updated")
    (options, args) = parser.parse_args()

    if len(args) != 2:
        parser.print_help()
        sys.exit()

    if options.checksum:
        diff_method = diff_by_hash

    else:
        diff_method = diff_by_size

    sys.stdout.write("Beginning sync %s to %s ...\n" % (args[0], args[1]))

    result = sync(args[0], args[1], diff_method)

    if result:
        sys.stdout.write("Sync done.\n")
        sys.exit(0)

    else:
        sys.stderr.write("Sync failed.\n")
        sys.exit(1)

