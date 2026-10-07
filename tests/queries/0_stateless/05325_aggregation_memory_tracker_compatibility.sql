-- https://github.com/ClickHouse/ClickHouse/issues/123756: under `compatibility` < 26.7 the two-level conversion of `GROUP BY` uses the old memory measurement.

SET max_memory_usage = '1Gi';
SET group_by_two_level_threshold_bytes = 50000000;
SET enable_lazy_columns_replication = 0;
SET optimize_aggregation_in_order = 0;
SET max_bytes_before_external_group_by = 0;
SET max_bytes_ratio_before_external_group_by = 0.5;

DROP TABLE IF EXISTS t_aggregation_memory_tracker;
CREATE TABLE t_aggregation_memory_tracker (c1 String, c2 String, c3 DateTime64(3)) ENGINE = MergeTree ORDER BY (c1, c3);
INSERT INTO t_aggregation_memory_tracker
SELECT concat('ch', toString(number % 600)), concat('v', toString(number)), toDateTime64('2024-01-01 00:00:00', 3) + toIntervalSecond(sipHash64(number) % 30000000)
FROM numbers(300000);

SELECT sum(x4)
FROM
(
    SELECT c1, arraySort(groupArray(p)) AS x2, arrayCount(i -> ((x2[i]) >= (x2[15])), range(16, toUInt32(length(x2)) + 1)) AS x4
    FROM (SELECT c1, c2, any(c3) AS p FROM t_aggregation_memory_tracker GROUP BY c1, c2)
    GROUP BY c1
)
SETTINGS compatibility = '25.8';

DROP TABLE t_aggregation_memory_tracker;
