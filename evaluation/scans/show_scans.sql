-- docker exec -i ... psql -U linux-fan masysma_dirstat < show_scans.sql
SELECT
	scans.name,
	COUNT(file_size)                                 AS num_files,
	SUM(file_size)/1024/1024                         AS size_mib,
	SUM(CASE WHEN file_size = 0 THEN 1 ELSE 0 END)   AS num_empty,
	(PERCENTILE_CONT(0.5)
		WITHIN GROUP (ORDER BY file_size))/1024  AS median_kib,
	AVG(file_size)/1024                              AS avg_kib,
	MAX(file_size)/1024/1024                         AS largest_mib,
	MAX(LENGTH(path))                                AS longst_path
FROM files
LEFT JOIN scans ON scans.id = files.scan
GROUP BY scans.name
ORDER BY scans.name ASC;
