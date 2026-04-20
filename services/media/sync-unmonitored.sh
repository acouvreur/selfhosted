#!/bin/bash
# Find files in download/complete that are not in movies or tvshows and optionally delete them.

set -euo pipefail

export DOWNLOAD_FOLDER="${PIDRIVE}/media/downloads/complete"
export MOVIES_FOLDER="${PIDRIVE}/media/movies"
export TVSHOWS_FOLDER="${PIDRIVE}/media/tvshows"

# Default settings
DRY_RUN=0
INTERACTIVE=0
TOTAL_FREED=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      echo "Running in DRY-RUN mode (no files will be deleted)"
      shift
      ;;
    --interactive|-i)
      INTERACTIVE=1
      echo "Running in INTERACTIVE mode"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--interactive|-i]"
      exit 1
      ;;
  esac
done

# Validate folders exist
if [[ ! -d "$DOWNLOAD_FOLDER" ]]; then
  echo "Error: DOWNLOAD_FOLDER does not exist: $DOWNLOAD_FOLDER"
  exit 1
fi

if [[ ! -d "$MOVIES_FOLDER" ]] || [[ ! -d "$TVSHOWS_FOLDER" ]]; then
  echo "Error: MOVIES_FOLDER or TVSHOWS_FOLDER does not exist"
  exit 1
fi

# Build a set of inodes from movies and tvshows folders for efficient lookup
declare -A EXISTING_INODES
while IFS= read -r inode; do
  EXISTING_INODES[$inode]=1
done < <(find "$MOVIES_FOLDER" "$TVSHOWS_FOLDER" -type f -printf '%i\n')

echo "Found ${#EXISTING_INODES[@]} files in movies/tvshows folders"
echo "Scanning for orphaned files in $DOWNLOAD_FOLDER..."
echo ""

# Check each large file in download folder
FILE_COUNT=0
DELETED_COUNT=0
WOULD_DELETE_COUNT=0
TOTAL_FREED=0
TOTAL_SCANNED_SIZE=0

while IFS=' ' read -r inode filesize filepath; do
  if [[ -z "$inode" ]] || [[ -z "$filesize" ]]; then
    continue
  fi
  
  FILE_COUNT=$((FILE_COUNT + 1))
  TOTAL_SCANNED_SIZE=$((TOTAL_SCANNED_SIZE + filesize))
  
  # Check if file's inode exists in movies or tvshows
  if [[ -z "${EXISTING_INODES[$inode]:-}" ]]; then
    filesize_human=$(numfmt --to=iec-i --suffix=B "$filesize")
    
    reason="Orphaned file (inode $inode not found in movies or tvshows)"
    WOULD_DELETE_COUNT=$((WOULD_DELETE_COUNT + 1))
    TOTAL_FREED=$((TOTAL_FREED + filesize))
    
    if [[ $INTERACTIVE -eq 1 ]]; then
      read -p "Delete? [$reason] ($filesize_human) $filepath [y/N]: " -r
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        continue
      fi
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[DRY-RUN] Would delete: $filepath ($filesize_human)"
    else
      echo "Deleting: $filepath ($filesize_human)"
      rm "$filepath"
      DELETED_COUNT=$((DELETED_COUNT + 1))
    fi
  fi
done < <(find "$DOWNLOAD_FOLDER" -type f -size +1G -printf '%i %s %p\n')

# Convert freed size to human-readable format
freed_human=$(numfmt --to=iec-i --suffix=B "$TOTAL_FREED")
scanned_human=$(numfmt --to=iec-i --suffix=B "$TOTAL_SCANNED_SIZE")

# Calculate percentage
freed_percent=0
if [[ $TOTAL_SCANNED_SIZE -gt 0 ]]; then
  freed_percent=$((TOTAL_FREED * 100 / TOTAL_SCANNED_SIZE))
fi

echo ""
echo "=== Summary ==="
if [[ $DRY_RUN -eq 1 ]]; then
  echo "Files that would be deleted: $WOULD_DELETE_COUNT out of $FILE_COUNT"
  echo "Space that would be freed: $freed_human out of $scanned_human ($freed_percent%)"
else
  echo "Files deleted: $DELETED_COUNT out of $FILE_COUNT"
  echo "Space freed: $freed_human out of $scanned_human ($freed_percent%)"
fi