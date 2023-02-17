FROM continuumio/miniconda3

# Avoid running jupyter as root.
RUN useradd --create-home --shell /bin/bash jupyter
USER jupyter
WORKDIR /home/jupyter

# Set up the "si_env" conda environment, lightly modified from a spikeinterface tutorial:
# https://github.com/SpikeInterface/spiketutorials/tree/master/Official_Tutorial_SI_0.96_Oct22
COPY ./environment.yml .
RUN conda env create -f environment.yml

# Include a notebook that can convert Plexon data to Phy.
COPY --chown=jupyter:jupyter ./plx_to_phy.ipynb /home/jupyter/notebooks/

# Send container commands through the "si_env" conda environment created above.
# This is roughly equivalent to "conda activate si_env".
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "si_env", "/bin/bash", "-c"]
