import os
import numpy as np
import pandas as pd

def add_distance_columns(df, lon_range=(2.20, 2.45), lat_range=(48.80, 48.92)):
    """
    Ajoute des colonnes de distances euclidiennes depuis chaque point du DataFrame
    vers les 4 coins de la zone et le centre.
    """
    # Coins de la zone
    top_left_lon,  top_left_lat  = lon_range[0], lat_range[1]
    top_right_lon, top_right_lat = lon_range[1], lat_range[1]
    bot_left_lon,  bot_left_lat  = lon_range[0], lat_range[0]
    bot_right_lon, bot_right_lat = lon_range[1], lat_range[0]
    # Centre
    center_lon = (lon_range[0] + lon_range[1]) / 2.0
    center_lat = (lat_range[0] + lat_range[1]) / 2.0

    df['dist_top_left'] = np.sqrt((df['lon'] - top_left_lon)**2 + (df['lat'] - top_left_lat)**2)
    df['dist_top_right'] = np.sqrt((df['lon'] - top_right_lon)**2 + (df['lat'] - top_right_lat)**2)
    df['dist_bottom_left'] = np.sqrt((df['lon'] - bot_left_lon)**2 + (df['lat'] - bot_left_lat)**2)
    df['dist_bottom_right'] = np.sqrt((df['lon'] - bot_right_lon)**2 + (df['lat'] - bot_right_lat)**2)
    df['dist_center'] = np.sqrt((df['lon'] - center_lon)**2 + (df['lat'] - center_lat)**2)

    return df

def enrich_csv_files_with_distances(input_folder='output_csv', output_folder='enriched_csv'):
    """
    Parcourt tous les fichiers CSV du dossier input_folder,
    ajoute les colonnes de distances, et sauvegarde dans output_folder.
    """
    os.makedirs(output_folder, exist_ok=True)

    for filename in os.listdir(input_folder):
        if filename.lower().endswith('.csv'):
            input_path = os.path.join(input_folder, filename)
            df = pd.read_csv(input_path)
            df_enriched = add_distance_columns(df)
            output_path = os.path.join(output_folder, filename)
            df_enriched.to_csv(output_path, index=False)
            print(f"Fichier enrichi : {output_path}")

if __name__ == "__main__":
    enrich_csv_files_with_distances(
        input_folder='output_csv',
        output_folder='enriched_csv'
    )
