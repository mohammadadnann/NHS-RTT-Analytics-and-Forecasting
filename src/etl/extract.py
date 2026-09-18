"""
Extract stage
Project: NHS RTT SQL Driven Business Analytics and Breach Risk Forecasting

This file only reads files from Azure Blob Storage. It does not clean or
reshape anything, that happens in transform.py instead.
"""

import re
from io import BytesIO

import pandas as pd
from azure.storage.blob import ContainerClient

from src.config import AZURE_STORAGE_CONNECTION_STRING, AZURE_CONTAINER_NAME


def get_container_client():
    return ContainerClient.from_connection_string(
        AZURE_STORAGE_CONNECTION_STRING, AZURE_CONTAINER_NAME
    )


def list_raw_files():
    # returns the blob names of every monthly RTT csv in the container,
    # sorted so I process them in date order
    container = get_container_client()
    blob_names = [b.name for b in container.list_blobs() if b.name.endswith("-full-extract.csv")]
    return sorted(blob_names)


def download_blob_to_dataframe(blob_name, usecols=None, nrows=None):
    # downloads one blob into memory and reads it as a csv, without
    # saving anything to local disk first
    container = get_container_client()
    blob_data = container.download_blob(blob_name).readall()
    return pd.read_csv(BytesIO(blob_data), encoding="utf-8-sig", usecols=usecols, nrows=nrows)


def read_csv_file(blob_name):
    return download_blob_to_dataframe(blob_name)


def get_period_date(blob_name):
    first_row = download_blob_to_dataframe(blob_name, usecols=["Period"], nrows=1)
    period_text = first_row["Period"].iloc[0].replace("RTT-", "")
    return pd.to_datetime(period_text, format="%B-%Y").date()


def get_band_columns(blob_name):
    sample = download_blob_to_dataframe(blob_name, nrows=5)
    band_columns = []
    for col in sample.columns:
        if re.match(r"^Gt \d+", col):
            band_columns.append(col)
    return band_columns