import numpy as np
import pandas as pd
import os
from geopy.distance import geodesic
from scipy.stats import skewnorm, rankdata
import gstools as gs


def check_distances(lon_range, lat_range):
    point1 = (lat_range[0], lon_range[0])
    point2 = (lat_range[1], lon_range[1])
    return geodesic(point1, point2).meters

def calculate_spatial_dependency_index(sill, nugget, range_, max_distance):
    if max_distance == 0:
        raise ValueError("La distance maximale ne peut pas être 0.")
    mf = 0.317
    normalized_range = range_ / max_distance
    if (sill + nugget) > 0:
        return mf * (sill / (sill + nugget)) * normalized_range * 100
    else:
        return 0

def impose_skewness(values, skewness_param):
    if skewness_param == 0:
        return values
    ranks = rankdata(values, method='ordinal')
    skewed = skewnorm.rvs(a=skewness_param, size=len(values))
    skewed = (skewed - np.mean(skewed)) / np.std(skewed)
    skewed_sorted = np.sort(skewed)
    transformed = np.zeros_like(values)
    for i, r in enumerate(ranks):
        transformed[i] = skewed_sorted[r - 1]
    return transformed

def simulate_spatial_data_gstools(
    grid_size=15,
    lon_range=(2.20, 2.45),
    lat_range=(48.80, 48.92),
    dependence_level='Strong',
    max_distance=None,
    skewness_param=0,
    seed=None
):
    if seed is not None:
        np.random.seed(seed)
    if max_distance is None:
        max_distance = check_distances(lon_range, lat_range)
    dependence_params = {
        'Weak':     {'sill': 0.1, 'nugget': 0.9, 'range_factor': 0.1},
        'Moderate': {'sill': 0.4, 'nugget': 0.6, 'range_factor': 0.3},
        'Strong':   {'sill': 0.9, 'nugget': 0.1, 'range_factor': 0.5}
    }
    params = dependence_params[dependence_level]
    sill = params['sill']
    nugget = params['nugget']
    effective_range = params['range_factor'] * max_distance
    x = np.linspace(0, 10000, grid_size)
    y = np.linspace(0, 10000, grid_size)
    model = gs.Exponential(dim=2, var=sill, len_scale=effective_range, nugget=nugget)
    srf = gs.SRF(model, seed=seed)
    values = srf.structured([x, y])
    values_flat = values.ravel()
    values_transformed = impose_skewness(values_flat, skewness_param)
    values = values_transformed.reshape(values.shape)
    lon = np.linspace(lon_range[0], lon_range[1], grid_size)
    lat = np.linspace(lat_range[0], lat_range[1], grid_size)
    grid_lon, grid_lat = np.meshgrid(lon, lat)
    df = pd.DataFrame({
        'lon': grid_lon.ravel(),
        'lat': grid_lat.ravel(),
        'value': values.ravel()
    })
    ids = calculate_spatial_dependency_index(sill, nugget, effective_range, max_distance)
    return df, ids


# Génération : grilles × combinaisons × simulations


def generate_datasets_with_square_grids(
    square_sizes,
    n_simulations=1000,
    base_seed=42
):
    dependence_levels = ['Weak', 'Moderate', 'Strong']
    skewness_levels = {
        'Negative': -5,
        'Neutral': 0,
        'Positive': 5
    }
    lon_range = (2.20, 2.45)
    lat_range = (48.80, 48.92)
    datasets = {}
    for grid_size in square_sizes:
        max_distance = check_distances(lon_range, lat_range)
        datasets[grid_size] = {}
        for dep in dependence_levels:
            for skew_name, skew_val in skewness_levels.items():
                combo_key = f"{dep.lower()}_dependence_{skew_name.lower()}_asymmetry"
                sim_list = []
                for i in range(n_simulations):
                    sim_seed = base_seed + i
                    df, ids = simulate_spatial_data_gstools(
                        grid_size=grid_size,
                        lon_range=lon_range,
                        lat_range=lat_range,
                        dependence_level=dep,
                        max_distance=max_distance,
                        skewness_param=skew_val,
                        seed=sim_seed
                    )
                    sim_list.append({'data': df, 'ids': ids})
                datasets[grid_size][combo_key] = sim_list
    return datasets


# Export CSV

def export_datasets_to_csv(datasets_by_grid_size, output_folder="output_csv"):
    os.makedirs(output_folder, exist_ok=True)
    dep_translations = {
        'weak': 'faible',
        'moderate': 'moyenne',
        'strong': 'forte'
    }
    asym_translations = {
        'negative': 'negative',
        'neutral': 'nulle',
        'positive': 'positive'
    }
    for grid_size, combos_dict in datasets_by_grid_size.items():
        for combo_key, sim_list in combos_dict.items():
            parts = combo_key.split('_')
            dep_str = dep_translations[parts[0]]
            asym_str = asym_translations[parts[2]]
            first_df = sim_list[0]['data'].copy()
            first_df = first_df.sort_values(by=['lat', 'lon']).reset_index(drop=True)
            wide_df = first_df[['lon', 'lat']].copy()
            for i, simulation_dict in enumerate(sim_list, start=1):
                df_i = simulation_dict['data'].copy()
                df_i = df_i.sort_values(by=['lat', 'lon']).reset_index(drop=True)
                wide_df[f'value_{i}'] = df_i['value'].values
            filename = f"{grid_size}x{grid_size}_dependance_{dep_str}_asymetrie_{asym_str}.csv"
            filepath = os.path.join(output_folder, filename)
            wide_df.to_csv(filepath, index=False)

