# Copyright (c) 2013-2014 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.
#
# Version:     0.2.0
#
# Author(s):   Yali Sassoon
# Copyright:   Copyright (c) 2013-2014 Snowplow Analytics Ltd
# License:     Apache License Version 2.0

- view: last_page
  derived_table:
    sql: |
       SELECT
        domain_userid,
        domain_sessionidx,
        domain_userid || '-' || domain_sessionidx AS visit_id,
        MAX(page_urlhost) AS page_urlhost, -- Remove duplicates (v. occasional case where two page views have exactly the same dvce_tstamp)
        MAX(page_urlpath) AS page_urlpath  -- Remove duplicates (v. occasional case where two page views have exactly the same dvce_tstamp)
        FROM (
          SELECT
          domain_userid,
          domain_sessionidx,
          page_urlhost,
          page_urlpath,
          RANK() OVER (PARTITION BY domain_userid, domain_sessionidx ORDER BY dvce_tstamp DESC) AS "rank_desc"
          FROM atomic.events
          WHERE event = 'page_view') AS a
        WHERE rank_desc = 1                -- Filter so only return landing pages
        GROUP BY 1,2,3                     -- Remove duplicates (v. occasional case where two page views have exactly the same dvce_tstamp)

    sql_trigger_value: | 
      SELECT 
      MAX(collector_tstamp)
      FROM atomic.events

  fields:
    
  # DIMENSIONS #
  
  - dimension: visit_id
    primary_key: true
    sql: ${TABLE}.visit_id
  
  - dimension: domain_userid
    sql: ${TABLE}.domain_userid
    hidden: true
    
  - dimension: domain_sessionidx
    type: int
    sql: ${TABLE}.domain_sessionidx
    hidden: true

  - dimension: host
    sql: ${TABLE}.page_urlhost
    
  - dimension: path
    sql: ${TABLE}.page_urlpath
    
  # MEASURES #
  
  - measure: page_views_count
    type: count
    detail: detail*
    
  # Detail #
  sets:
    detail:
      - domain_userid
      - domain_sessionidx
      - page_urlhost
      - page_urlpath