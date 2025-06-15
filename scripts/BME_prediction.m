clear; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data names %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
les_fichiers = {'9x9_dependance_faible_asymetrie_negative.xlsx', '9x9_dependance_faible_asymetrie_nulle.xlsx', '9x9_dependance_faible_asymetrie_positive.xlsx', '9x9_dependance_forte_asymetrie_negative.xlsx', '9x9_dependance_forte_asymetrie_nulle.xlsx', '9x9_dependance_forte_asymetrie_positive.xlsx', '9x9_dependance_moyenne_asymetrie_negative.xlsx', '9x9_dependance_moyenne_asymetrie_nulle.xlsx', '9x9_dependance_moyenne_asymetrie_positive.xlsx', '12x12_dependance_faible_asymetrie_negative.xlsx', '12x12_dependance_faible_asymetrie_nulle.xlsx', '12x12_dependance_faible_asymetrie_positive.xlsx', '12x12_dependance_forte_asymetrie_negative.xlsx', '12x12_dependance_forte_asymetrie_nulle.xlsx', '12x12_dependance_forte_asymetrie_positive.xlsx', '12x12_dependance_moyenne_asymetrie_negative.xlsx', '12x12_dependance_moyenne_asymetrie_nulle.xlsx', '12x12_dependance_moyenne_asymetrie_positive.xlsx', '15x15_dependance_faible_asymetrie_negative.xlsx', '15x15_dependance_faible_asymetrie_nulle.xlsx', '15x15_dependance_faible_asymetrie_positive.xlsx', '15x15_dependance_forte_asymetrie_negative.xlsx', '15x15_dependance_forte_asymetrie_nulle.xlsx', '15x15_dependance_forte_asymetrie_positive.xlsx', '15x15_dependance_moyenne_asymetrie_negative.xlsx', '15x15_dependance_moyenne_asymetrie_nulle.xlsx', '15x15_dependance_moyenne_asymetrie_positive.xlsx', '18x18_dependance_faible_asymetrie_negative.xlsx', '18x18_dependance_faible_asymetrie_nulle.xlsx', '18x18_dependance_faible_asymetrie_positive.xlsx', '18x18_dependance_forte_asymetrie_negative.xlsx', '18x18_dependance_forte_asymetrie_nulle.xlsx', '18x18_dependance_forte_asymetrie_positive.xlsx', '18x18_dependance_moyenne_asymetrie_negative.xlsx', '18x18_dependance_moyenne_asymetrie_nulle.xlsx', '18x18_dependance_moyenne_asymetrie_positive.xlsx', '21x21_dependance_faible_asymetrie_negative.xlsx', '21x21_dependance_faible_asymetrie_nulle.xlsx', '21x21_dependance_faible_asymetrie_positive.xlsx', '21x21_dependance_forte_asymetrie_negative.xlsx', '21x21_dependance_forte_asymetrie_nulle.xlsx', '21x21_dependance_forte_asymetrie_positive.xlsx', '21x21_dependance_moyenne_asymetrie_negative.xlsx', '21x21_dependance_moyenne_asymetrie_nulle.xlsx', '21x21_dependance_moyenne_asymetrie_positive.xlsx'};
ds_names = {'WN_81_xlsx', 'WS_81_xlsx', 'WP_81_xlsx', 'SN_81_xlsx', 'SS_81_xlsx', 'SP_81_xlsx', 'MN_81_xlsx', 'MS_81_xlsx', 'MP_81_xlsx', 'WN_144_xlsx', 'WS_144_xlsx', 'WP_144_xlsx', 'SN_144_xlsx', 'SS_144_xlsx', 'SP_144_xlsx', 'MN_144_xlsx', 'MS_144_xlsx', 'MP_144_xlsx', 'WN_225_xlsx', 'WS_225_xlsx', 'WP_225_xlsx', 'SN_225_xlsx', 'SS_225_xlsx', 'SP_225_xlsx', 'MN_225_xlsx', 'MS_225_xlsx', 'MP_225_xlsx', 'WN_324_xlsx', 'WS_324_xlsx', 'WP_324_xlsx', 'SN_324_xlsx', 'SS_324_xlsx', 'SP_324_xlsx', 'MN_324_xlsx', 'MS_324_xlsx', 'MP_324_xlsx', 'WN_441_xlsx', 'WS_441_xlsx', 'WP_441_xlsx', 'SN_441_xlsx', 'SS_441_xlsx', 'SP_441_xlsx', 'MN_441_xlsx', 'MS_441_xlsx', 'MP_441_xlsx'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%
dmax = 22684.63;
nombre_limite = 1002;
delta_max = 1.5;  % Max incertitude pour les intervalles soft
rng(42);  % Graine pour reproductibilité

bar = waitbar(1, 'Program is running, please wait');

for fileIndex = 1:length(les_fichiers)
    nom_fichier = strcat('../outputs_excel/', les_fichiers{fileIndex});
    ds_list = xlsread(nom_fichier);
    
    raw_data = ds_list;
    n = size(raw_data, 1);

    filename = ds_names{fileIndex};
    sheetname = 'Sheet1';

    outputs = cell(1000, 1);

    if filename(1) == 'W'
        rang = dmax / 10;
    elseif filename(1) == 'M'
        rang = dmax * 3 / 10;
    elseif filename(1) == 'S'
        rang = dmax / 2;
    end

    min = 3; max = nombre_limite;

    for j = min:max
        niveau = (j - min + 1) / (max - min);
        waitbar(niveau, bar, strcat(num2str(niveau * 100), '/100 Program is running, please wait'));

        HD = raw_data(:, [1 2 j]);
        train = HD(1:ceil(n * 0.7), :);
        test = HD(ceil(n * 0.7) + 1:end, :);
        ch = train(:, 1:2);
        zh = train(:, 3);
        ck = test(:, 1:2);
        zht = test(:, 3);

        covmodel = 'exponentialC'; 
        nhmax = length(ch); 
        nsmax = 0;
        order = NaN;
        cs = ck;
        covparam = [1 rang];

        % Générer les intervalles pour chaque point de training
        epsilon = rand(length(ch), 1) * delta_max;
        a = zh - epsilon;
        b = zh + epsilon;

        zkBME = BMEintervalMode(ck, ch, cs, zh, a, b, covmodel, covparam, nhmax, nsmax, dmax, order);

        BME_MAE = mean(abs(zkBME - zht));
        BME_RMSE = sqrt(mean((zkBME - zht).^2));
        outputs{j} = [BME_MAE BME_RMSE];

        pause(0.02);
    end

    result = cell2mat(outputs);
    A_table = array2table(result, 'VariableNames', {'MAE', 'RMSE'});

    repertoire = '../Output_BME/BME_';
    nom_fichier = strcat(repertoire, filename, '.xlsx');
    writetable(A_table, nom_fichier);
end

close(bar);
