# set up ssh tunneling and connect to database
source(here::here("R", "connect.R"))
connection <- connect()
cn <- connection[[2]]

# read SQL script and break it up into a list of strings, 
# where each list element is a single SQL command
commands <- readr::read_file(here::here("DB_setup", "forwardEngineer.sql")) %>%
  stringr::str_replace_all("[\r\n]", "") %>%
  stringr::str_split(pattern = ";") %>%
  unlist()

# run SQL commands
for(command in commands){
  print(command)
  dbExecute(cn, command)
}

# disconnect from database
dbDisconnect(cn)
