#!/usr/bin/php -f
<?php
# Ma_Sys.ma Script to Evaluate changes between DirStat 2 scans 1.0.0
# Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.
#
# REQUIREMENTS
# 	php-pgsql
#
# OUTPUT
# 	from_id;to_id;added_files;added_mib;removed_files;removed_mib;
# 	changed_files;changed_mib;sum_files;sum_mib

error_reporting(E_ALL | E_NOTICE);

$db      = new PDO("pgsql:host=127.0.0.1;port=5432;dbname=masysma_dirstat",
			"linux-fan", "testwort",
			[PDO::ATTR_PERSISTENT => 0,
			PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

$stmt    = $db->prepare("SELECT id, paths FROM scans WHERE name = :name");

$from_st = $argv[1];
$stmt->execute([":name" => $from_st]);
$from    = $stmt->fetch(PDO::FETCH_ASSOC) or die("No results for from.\n");
$stmt->closeCursor();
$from_id = $from["id"];
$length1 = strlen($from["paths"]) - 1; # assumption: just one element in array

$to_st   = $argv[2];
$stmt->execute([":name" => $to_st]);
$to      = $stmt->fetch(PDO::FETCH_ASSOC) or die("No results for to.\n");
$stmt->closeCursor();
$to_id   = $to["id"];
$length2 = strlen($to["paths"]) - 1;

$stmt = $db->prepare(
	"SELECT COUNT(file_additions.localpath) AS added_files,
	SUM(file_additions.file_size)/1024/1024 AS added_mib FROM (
		SELECT SUBSTR(f1.path, :length2) AS localpath, f1.file_size
		FROM files f1
		WHERE f1.scan = :to_id
		EXCEPT
		SELECT SUBSTR(f2.path, :length1) AS localpath, f1x.file_size
		FROM files f2, files f1x
		WHERE f2.scan = :from_id AND f1x.scan = :to_id AND
		SUBSTR(f1x.path, :length2) = SUBSTR(f2.path, :length1)
	) file_additions"
);
$stmt->execute([":from_id" => $from_id, ":to_id" => $to_id,
		":length1" => $length1, ":length2" => $length2]);
# added_files, added_mib
$add = $stmt->fetch(PDO::FETCH_ASSOC) or die("No results for add.\n");
$stmt->closeCursor();

$stmt = $db->prepare(
	"SELECT COUNT(file_removals.localpath) AS removed_files,
	SUM(file_removals.file_size)/1024/1024 AS removed_mib FROM (
		SELECT SUBSTR(f1.path, :length1) AS localpath, f1.file_size
		FROM files f1
		WHERE f1.scan = :from_id
		EXCEPT
		SELECT SUBSTR(f2.path, :length2) AS localpath, f1x.file_size
		FROM files f2, files f1x
		WHERE f2.scan = :to_id AND f1x.scan = :from_id AND
		SUBSTR(f1x.path, :length1) = SUBSTR(f2.path, :length2)
	) file_removals"
);
$stmt->execute([":from_id" => $from_id, ":to_id" => $to_id,
		":length1" => $length1, ":length2" => $length2]);
# removed_files, removed_mib
$del = $stmt->fetch(PDO::FETCH_ASSOC) or die("No results for del.\n");
$stmt->closeCursor();

$stmt = $db->prepare(
	"SELECT COUNT(f1.path) AS changed_files,
		SUM(f1.file_size)/1024/1024 AS changed_mib 
	FROM    files f1, files f2
	WHERE   f1.scan = :from_id AND f2.scan = :to_id AND
		SUBSTR(f1.path, :length1) = SUBSTR(f2.path, :length2) AND
		(f2.time_mod <> f1.time_mod OR f1.file_size <> f2.file_size)"
);
$stmt->execute([":from_id" => $from_id, ":to_id" => $to_id,
		":length1" => $length1, ":length2" => $length2]);
# changed_files, changed_mib
$chg = $stmt->fetch(PDO::FETCH_ASSOC) or die("No results for chg.\n");
$stmt->closeCursor();

$d_files = $add["added_files"] + $chg["changed_files"] - $del["removed_files"];
$d_mib   = $add["added_mib"]   + $chg["changed_mib"]   - $del["removed_mib"];

echo("$from_st;$to_st;".$add["added_files"].";".$add["added_mib"].";".
	$del["removed_files"].";".$del["removed_mib"].";".$chg["changed_files"].
	";".$chg["changed_mib"].";$d_files;$d_mib\n");

$stmt = null;
$db = null;
# EXIT 0
