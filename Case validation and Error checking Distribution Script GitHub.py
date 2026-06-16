'''
This script keeps notes from previous lists and attaches them to new list pulls
It maintains continuity for LM Users when cleaning data.
Enter the correct file names and store the files in the correct file paths.
This process can easily be integrated to workflows.

Instructions: Insert the correct file paths. Make sure those files are consistently following the same template.
1) run SQL script attached
2) insert file paths, include previous work files, previous county assignments, and new updated file.
3) run and keep track of work product
4) Send via teams, also give access to coworkers
'''

import os
import pandas as pd
import openpyxl as ox

new_dir = 'C:/Users/ema/Documents/PycharmProjects/LM Cleaning and Notes Joining/Inputs/New File/'

prev_dir = 'C:/Users/ema/PycharmProjects/LM Cleaning and Notes Joining/Inputs/Previous File/'

write_path = 'C:/Users/ema//Documents/PycharmProjects/LM Cleaning and Notes Joining/Outputs/'

######################################################
######VVVV## Input Previous Data Criteria ##VVVV######
######################################################
new_file = 'LM No NCD since all time 6.16.26.xlsx'

prev_file_1 = 'Law Manager NoNCD since all time Continued 6.9.26 EM.xlsx'
prev_file_2 = 'Law Manager NoNCD since all time Continued 6.9.26 JW.xlsx'

write_file = 'Law Manager NoNCD since all time Continued 6.16.26.xlsx'

#Previous Week's assignment by county
EM_prev = ["New York", "Bronx", "Richmond"]
JW_prev = ["Kings", "Queens"]

##########################################
###/\/\/\## Input New File Name #/\/\/\###
##########################################

#concat file directories
new_file = os.path.join(new_dir, new_file)

prev_file_1 = os.path.join(prev_dir, prev_file_1)
prev_file_2 = os.path.join(prev_dir, prev_file_2)

write_path = os.path.join(write_path, write_file)


###########################################
############### Merge Files ###############
###########################################

#read files
new_file = pd.read_excel(new_file)
prev_file_1 = pd.read_excel(prev_file_1)
prev_file_2 = pd.read_excel(prev_file_2)

#format
prev_file_1['county'] = prev_file_1['county'].str.strip()
prev_file_2['county'] = prev_file_2['county'].str.strip()

#parse previous files by county assignments
prev_file_1 = prev_file_1.loc[prev_file_1['county'].isin(EM_prev)]
prev_file_2 = prev_file_2.loc[prev_file_2['county'].isin(JW_prev)]

#parse trim prev file
prev_file_1 = pd.DataFrame(prev_file_1, columns=['matter_key', 'Notes'])
prev_file_2 = pd.DataFrame(prev_file_2, columns=['matter_key', 'Notes'])

#process new file
new_file['county'] = new_file['county'].str.strip()
new_file_1 = new_file.loc[new_file['county'].isin(EM_prev)]
new_file_2 = new_file.loc[new_file['county'].isin(JW_prev)]

#Retrieve updates/notes from previous files
prev_file_1 = pd.merge(new_file_1, prev_file_1, on='matter_key',how='left')
prev_file_2 = pd.merge(new_file_2, prev_file_2, on='matter_key',how='left')

#Merge files
merged_file = pd.concat([prev_file_1, prev_file_2])
merged_file.sort_values(by=['county','NYSID','Recommended_Checks'])

#write files
merged_file.to_excel(write_path, index=False)

#Docket distribution
boro_count = merged_file['county'].value_counts(normalize=False)
print(f"NCD Borough Distribution: {boro_count}")






