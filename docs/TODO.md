TODO LIST


1. Simplify The Border System (3 Systems Only)
- default border state (greyed border normal setting) -> for all variants of cleaning and occupancy status whatever
 - remove all other border combos lets greatly simplify it
- if room is occcupied (greyed in like it currently is)
- if room is vacant (not greyed in)
 
 Basically remove all borders go to default border and then have a state for the occupeid where it is shadowede in card like it currently is and then no shadow if not occupied
 
 2. Status Taxonomy
 - use supabase mcp and change enum for cleaning status from (dirty, cleaning, inspected) to (dirty, cleaning, ready)
 - also change value after chanign tbale value using supabase mcp
 - change all references of inspected ot ready everywher eon the room dashboard
 

3. Note Icon
- Add anode badge on the card above the updateed part whne notes exist(past 48 hours)
- Just shows note is present quickly

4. Updated At
- Create service that shows latest time that the room has been updated inside respective service folder
- Change the updated hardcoded from 12m ago to actually whatever time it has been recently updated (ex: 5 min ago)
- Optimize it make sure its not constatnly pulling yk find th ebest way to achieve this\



