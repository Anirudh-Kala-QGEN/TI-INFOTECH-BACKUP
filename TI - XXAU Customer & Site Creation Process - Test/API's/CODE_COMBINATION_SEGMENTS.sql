/*-------------------------------------------------------------------------------------------------
								Category -- AUPL_Chart_Of_Account
-------------------------------------------------------------------------------------------------*/

--  AUPL_Company - SEGMENT 1
SELECT   FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Company'
                              AND h.hierarchy_name LIKE ''))))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Company'))
		 AND ENABLED_FLAG = 'Y'
		 AND FLEX_VALUE = (SELECT ORGANIZATION_CODE FROM ORG_ORGANIZATION_DEFINITIONS WHERE ORGANIZATION_ID = 265)
ORDER BY flex_value

-- AUPL_Location - SEGMENT 3
/* Formatted on 4/7/2026 2:51:34 PM (QP5 v5.365) */
SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Location'
                              AND h.hierarchy_name LIKE ''))))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Location'))
		 AND ENABLED_FLAG = 'Y'
ORDER BY flex_value

-- AUPL_Department - SEGMENT 4
/* Formatted on 4/7/2026 2:53:32 PM (QP5 v5.365) */
SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Department')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Department'))
		 AND ENABLED_FLAG = 'Y'
ORDER BY flex_value

-- AUPL_Natural_Account -- SEGMENT 5
/* Formatted on 4/7/2026 2:55:07 PM (QP5 v5.365) */
SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Natural_Account')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Natural_Account'))
		 AND ENABLED_FLAG = 'Y'
ORDER BY flex_value


-- AUPL_Division Location -- SEGMENT 8
/* Formatted on 4/7/2026 2:56:54 PM (QP5 v5.365) */
SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Division Location')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Division Location'))
		 AND ENABLED_FLAG = 'Y'
ORDER BY flex_value


-- AUPL_Activity -- SEGMENT 9/* Formatted on 4/7/2026 2:58:39 PM (QP5 v5.365) */
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Activity')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AUPL_Activity'))
         AND ENABLED_FLAG = 'Y'
ORDER BY flex_value

/*-------------------------------------------------------------------------------------------------
										Category - AU_COA
-------------------------------------------------------------------------------------------------*/
-- AU_COMPANY - SEGMENT1
/* Formatted on 4/7/2026 3:23:47 PM (QP5 v5.365) */
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_COMPANY')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_COMPANY'))
ORDER BY flex_value

-- AU_DAK - SEGMENT 2
/* Formatted on 4/7/2026 3:23:47 PM (QP5 v5.365) */
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_DAK')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_DAK'))
ORDER BY flex_value

-- AU_LOCATION - SEGMENT 3
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_LOCATION')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_LOCATION'))
ORDER BY flex_value


-- AU_DEPARTMENT - SEGMENT 4
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_DEPARTMENT')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_DEPARTMENT'))
ORDER BY flex_value

-- AU_NATURAL_ACCOUNT - SEGMENT 5
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_NATURAL_ACCOUNT')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_NATURAL_ACCOUNT'))
ORDER BY flex_value


-- AU_INTER_COMPANY - SEGMENT 6
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_INTER_COMPANY')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_INTER_COMPANY'))
ORDER BY flex_value

-- AU_SPARE - SEGMENT 7
SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_SPARE')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'AU_SPARE'))
ORDER BY flex_value


/*-------------------------------------------------------------------------------------------------
									Category - IPPL_Chart_Of_Account
-------------------------------------------------------------------------------------------------*/

-- IPPL_COMPANY - SEGMENT1
/* Formatted on 4/7/2026 3:23:47 PM (QP5 v5.365) */
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_COMPANY')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_COMPANY'))
ORDER BY flex_value

-- IPPL_LOCATION - SEGMENT 3
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_LOCATION')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_LOCATION'))
ORDER BY flex_value


-- IPPL_Department - SEGMENT 4
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_Department')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_Department'))
ORDER BY flex_value

-- IPPL_Natural Account - SEGMENT 5
  SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_Natural Account')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_Natural Account'))
ORDER BY flex_value


-- IPPL_Business Type - SEGMENT 8
SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_Business Type')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_Business Type'))
ORDER BY flex_value

-- IPPL_Job Activity - SEGMENT 9
SELECT FLEX_VALUE,
         FLEX_VALUE_MEANING,
         DESCRIPTION,
         ENABLED_FLAG,
         START_DATE_ACTIVE,
         END_DATE_ACTIVE,
         SUMMARY_FLAG,
         HIERARCHY_LEVEL,
         FLEX_VALUE_SET_ID,
         PARENT_FLEX_VALUE_LOW,
         PARENT_FLEX_VALUE_HIGH,
         FLEX_VALUE_ID
    FROM FND_FLEX_VALUES_VL
   WHERE     (   ('' IS NULL)
              OR (structured_hierarchy_level IN
                      (SELECT hierarchy_id
                         FROM fnd_flex_hierarchies_vl h
                        WHERE     h.flex_value_set_id = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_Job Activity')
                              AND h.hierarchy_name LIKE '')))
         AND (FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
                                    FROM FND_FLEX_VALUE_SETS
                                    WHERE FLEX_VALUE_SET_NAME = 'IPPL_Job Activity'))
ORDER BY flex_value