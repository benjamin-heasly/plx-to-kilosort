FROM continuumio/miniconda3

# Avoid running jupyter as root.
RUN useradd --create-home --shell /bin/bash jupyter
USER jupyter
WORKDIR /home/jupyter

# Set up the "si_env" conda environment, lightly modified from a spikeinterface tutorial:
# https://github.com/SpikeInterface/spiketutorials/tree/master/Official_Tutorial_SI_0.96_Oct22
COPY environment.yml .
RUN conda env create -f environment.yml

# Send container commands through the same conda environment.
# This is roughly equivalent to "conda activate si_env".
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "si_env", "/bin/bash", "-c"]
