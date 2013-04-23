
/* Note: Inventory as a property of stock */

/* Inventory for strain with DBS ID */
SELECT s.uniquename, cvterm.name, stp.value
FROM stock s
JOIN stockprop stp ON stp.stock_id = s.stock_id
JOIN cvterm ON cvterm.cvterm_id = stp.type_id
JOIN cv ON cv.cv_id = cvterm.cv_id
WHERE cv.name = 'strain_inventory'
AND s.uniquename = 'DBS0349837'
;

/* How many inventories does a stock have? */
SELECT s.uniquename, COUNT(stp.stock_id)
FROM stock s
JOIN stockprop stp ON stp.stock_id = s.stock_id
GROUP BY s.uniquename
ORDER BY s.uniquename
;

/* Get inventory for a particular color */
SELECT

;

/* NOTE: If using HSTORE, the above query can be done as */
SELECT s.uniquename, stp.value
FROM stock s
JOIN stockprop stp ON stp.stock_id = s.stock_id
WHERE stp.value->color = 'yellow'
;
