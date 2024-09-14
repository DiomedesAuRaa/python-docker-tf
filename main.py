from fastapi import FastAPI, HTTPException
import requests

app = FastAPI()

@app.get("/poet/{letter}")
async def get_poet_by_letter(letter: str):
    if len(letter) != 1 or not letter.isalpha():
        raise HTTPException(status_code=400, detail="Input must be a single English letter.")
    
    response = requests.get("https://poetrydb.org/author")
    if response.status_code != 200:
        raise HTTPException(status_code=500, detail="Error fetching data from PoetryDB.")
    
    poets = response.json()  # Expecting a list of poet names
    
    # Filter poets by first letter, case insensitive
    matching_poets = [poet for poet in poets if poet.startswith(letter.upper())]
    
    if matching_poets:
        return {"poet": matching_poets[0]}  # Return the first match
    
    raise HTTPException(status_code=404, detail="No poet found with that initial.")