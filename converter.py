import pandas as pd
import sqlite3  # No need to install, it's built into Python

# Load Excel file
df = pd.read_excel(".\Jagruti_Citywise.xlsx")

# Connect to SQLite and create database
conn = sqlite3.connect("jagruti.db")

# Save the DataFrame to SQLite table
df.to_sql("contacts", conn, if_exists="replace", index=False)

# Close the connection
conn.close()

print("Database created: jagruti.db")