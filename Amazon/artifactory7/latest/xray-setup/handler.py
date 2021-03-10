from __future__ import print_function
from crhelper import CfnResource
import logging
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

logger = logging.getLogger(__name__)
# Initialise the helper, all inputs are optional, this example shows the defaults
helper = CfnResource(json_logging=False, log_level='DEBUG', boto_level='CRITICAL', sleep_on_delete=120)

@helper.create
def create(event, context):
    conn = None
    try:
        logger.info("Got Create. Connecting to db")
        conn = psycopg2.connect(
            dbname=event['ResourceProperties']['XrayMasterDatabaseUrl'].split("/")[1].split("?")[0], 
            user=event['ResourceProperties']['DatabaseUser'], 
            host=event['ResourceProperties']['XrayMasterDatabaseUrl'].split(":")[0],
            password=event['ResourceProperties']['DatabasePassword']
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cur = conn.cursor()
        logger.info("Start Queries")
        cur.execute(f"CREATE USER {event['ResourceProperties']['XrayDatabaseUser']} WITH PASSWORD \'{event['ResourceProperties']['XrayDatabasePassword']}\';")
        cur.execute(f"GRANT {event['ResourceProperties']['XrayDatabaseUser']} to {event['ResourceProperties']['DatabaseUser']};")
        cur.execute(f"CREATE DATABASE xraydb WITH OWNER={event['ResourceProperties']['XrayDatabaseUser']};")
        cur.execute(f"GRANT ALL PRIVILEGES ON DATABASE xraydb TO {event['ResourceProperties']['XrayDatabaseUser']};")
        cur.close()
        logger.info("End Queries")
    except psycopg2.DatabaseError as e:
        raise ValueError(e)
    finally:
        if conn:
            conn.close()

@helper.update
@helper.delete
def noop(event, context):
    pass

def handler(event, context):
    helper(event, context)
