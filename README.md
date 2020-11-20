
# kea-wiki-extraction

This shell script extracts various information from the Wikipdia which is needed by our entity linking tool.

The script is based on the German language dumps. 

The following is extracted:

- **Labels** for entities
- **Links** between entities
- **Norm data** (e.g. GND, VIAF, etc.)

The labels are generated from the article name, anchor texts of links between 
articles, redirects and disambiguation pages. The links are extracted e.g. to build a PageLink graph. 

For compatibility reasons we're running the script in an Ubuntu Docker container (cf. `run.sh`). The actual script `wiki-extraction.sh` can be found in the `work` directory.

After running `run.sh` the following data will be output

- ``labels.txt``containing the labels: The first column represents the entity, the second column represets the label. The columns are separated by whitespace. Whitespace within each item is replaced by underscore. 
- ``links.txt`` contains the links between entities. The columns are separated by whitespace.
- ``entities.txt`` list of all entities
- ``normdata.txt`` contians the extracted nom data information. The first column represents the entity, the second the norm data fragment extracted. 
- ``categories.txt`` list of category links

