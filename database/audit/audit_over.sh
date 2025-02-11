#!/bin/sh
# Make the script executable by running the following command in the terminal
# chmod +x audit_over.sh

# Check if arguments are provided
# If not (arguments'#$' is not equal '-ne' to 2), it prints: 'Usage: ./audit_over.sh <audit_table> <from>'
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <table> <from>"
    exit 1
fi

# Assign arguments to variables
TABLE="$1"
FROM="$2"

# Define the column to exclude
COLUMN_TO_EXCLUDE="geom"

# Define PostgreSQL connection parameters
HOST="localhost"
USERNAME="zwarott"
DATABASE="pto_opavsko"

# Get the list of columns excluding the specific column
COLUMNS=$(psql -h "$HOST" -U "$USERNAME" -d "$DATABASE" -t -c "
  SELECT string_agg(column_name, ', ')
  FROM information_schema.columns
  WHERE table_name = '${TABLE}_history' AND column_name != '$COLUMN_TO_EXCLUDE'
")

# Show me changes in selected table from specific date
# Need to use single quotes to converts arguments into strings
# Add <<EOF EOF that allows to include a block of SQL query
# in more readable way
psql -h "$HOST" -U "$USERNAME" -d "$DATABASE"  <<EOF
  SELECT 
    $COLUMNS
  FROM 
    audit.${TABLE}_history
  WHERE
    tstzrange('$FROM', now(), '[)') && valid_range AND
        (
          lower(valid_range) < now()::timestamp AND
          lower(valid_range) >= '$FROM'::timestamp
        )
  ORDER BY
    hid DESC;
EOF
