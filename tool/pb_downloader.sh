#!/bin/bash

OnInit() {
    REGEX='(.*/seg-)[0-9]{1,}(-.*)'
    LIST=list.txt
    TARGET=./pronhub
    LOG=/tmp/pb.log
    TMP_VIDEO='0*.mp4'
    END_TAG='Not Found'
    DENY_TAG='Unauthorized'
    MIN_SIZE=404
    mkdir -p $TARGET
    trap 'CheckCmd && OnDownloadSuccess' EXIT
    trap OnInterrupt INT
}

OnDownloadSuccess() {
    rm -f $LOG $LIST $TMP_VIDEO
    mv $g_out $TARGET
}

OnInterrupt() { exit 1; }

FileSize() { stat --format=%s $1; }

CheckCmd() { return $?; }

ParseOutputName() {
    declare -g g_out
    readonly local L=',' R='.urlset'
    g_out=${1%$R*}
    g_out=${g_out##*$L}
    [ $g_out ]
}

StreamEnd() { [ $(FileSize $1) -le $MIN_SIZE ] && grep -q "$END_TAG" $1; }

BatchDeny() {
    head --bytes=173 $1 | grep -q $DENY_TAG
}

UrlParser() {
    declare -g g_left g_right
    local s SEP=' '
    s=$(echo $1 | sed -E "s#$REGEX#\1$SEP\2#")
    g_left=${s%$SEP*}
    g_right=${s#*$SEP}
    [ $g_left ] && [ $g_right ]
}

Downloader() { curl -L $1 -o $2; }

StreamDownloader() {
    local i j out rc
    StreamFilter
    for ((i = $1, j = ${2-999}; i < $j; ++i)); do
        out=$(printf "%04d" $i)$g_out
        test -f $out && continue
        Downloader $g_left$i$g_right $out
        rc=$?
        [ $rc -eq 92 ] && {
            sleep 5
            ((--i))
            continue
        }
        [ $rc -eq 0 ] || return 1
        [ $i -eq 1 ] && BatchDeny $out
        CheckCmd && rm $out && return 2
        StreamEnd $out && rm $out && break
    done
    return 0
}

# Filter invalid segment (due to previous download failure)
StreamFilter() { find . -type f -size -${MIN_SIZE}c -delete; }

StartDownload() { ParseOutputName "$1" && UrlParser "$1" && StreamDownloader 1; }

StreamConcat() {
    echo $TMP_VIDEO | awk '{for(i=1;i<=NF;++i) print "file "$i}' >$LIST
    ffmpeg -safe 0 -f concat -i $LIST -c copy $g_out
}

main() {
    OnInit
    StartDownload "$1" && StreamConcat &>$LOG
    set -x
}
main "$@"
