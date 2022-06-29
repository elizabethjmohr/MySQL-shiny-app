The following describes the purpose of each of the following scripts:

- *create.R*: re-creates the database from scratch by running an SQL script that 
drops the schema and all tables before re-creating them. DO NOT run this script 
unless it's necessary to wipe out the existing database and start over.

- *forwardEngineer.sql*: SQL that gets run by create.R in order to in order
to recreate the database from scratch.

- *setup.R*: defines valid metrics, labs, loggers, locations, and treatments in 
order to prepare the database for loading of experimental data. It can be used 
to add new valid entries within each of the tables listed above by adding a 
new row to the appropriate tibble and executing the corresponding INSERT statement.

- *insert.R*: reads in experimental data from storage on sharepoint site 
and loads it into the database. 

- *create_eml_metadata.R* : generates a metadata file using the EML schema to
describe all tables and fields in the database. 


