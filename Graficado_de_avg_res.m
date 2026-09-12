% --- 1. CONFIGURACIÓN DE LOS PARÁMETROS GLOBALES ---
patrones = {'+', 'G', 'O', 'r', 'f'}; %[cite: 1]
lista_grosores = {'1.5mm', '2mm'};
lista_longitudes = {'10cm', '15cm'};
lista_probetas = {'1', '2'};

clc; 
fprintf('=== INICIANDO BARRIDO MASIVO DE TODAS LAS CONFIGURACIONES ===\n'); 

% --- 2. SELECCIÓN DE CARPETA ---
carpeta_archivos = uigetdir(pwd, 'Selecciona la carpeta de los Excels'); %[cite: 1]
if carpeta_archivos == 0, return; end %[cite: 1]

archivos = dir(fullfile(carpeta_archivos, '*.xlsx')); %[cite: 1]
archivos = archivos(~startsWith({archivos.name}, '~')); %[cite: 1]

% --- 3. BUCLE EXTERNO: RECORRER TODAS LAS COMBINACIONES ---
for g = 1:length(lista_grosores)
    for l = 1:length(lista_longitudes)
        for pr = 1:length(lista_probetas)
            
            grosor_objetivo = lista_grosores{g};
            longitud_objetivo = lista_longitudes{l};
            numero_probeta = lista_probetas{pr};
            
            fprintf('\n--- Procesando: Grosor %s | Longitud %s | Probeta/Lote %s ---\n', ...
                grosor_objetivo, longitud_objetivo, numero_probeta);
            
            % Preparación de la figura para esta combinación específica
            nombre_fig = sprintf('Config_Grosor_%s_Long_%s_Prob_%s', grosor_objetivo, longitud_objetivo, numero_probeta);
            fig_res = figure('Name', nombre_fig, 'Position', [50, 50, 1000, 900], 'Visible', 'off'); 
            t_res = tiledlayout(5, 1, 'TileSpacing', 'compact'); %[cite: 1]
            
            % Especificar claramente el caso en la parte superior de la figura
            sgtitle(sprintf('CONFIGURACIÓN: Grosor = %s | Longitud = %s | Probeta = %s', ...
                grosor_objetivo, longitud_objetivo, numero_probeta), 'FontSize', 13, 'FontWeight', 'bold');
            
            xlabel(t_res, 'Time (s)', 'FontWeight', 'bold'); %[cite: 1]
            ylabel(t_res, 'Resistencia (\Omega)', 'FontWeight', 'bold');

            zoom_T5_capturado = false;
            hay_datos_totales = false;
            
            % --- 4. PROCESAMIENTO POR PATRÓN ---
            for p = 1:length(patrones) %[cite: 1]
                patron = patrones{p}; %[cite: 1]
                id_probeta = sprintf('%s%s_%s_%s', patron, numero_probeta, grosor_objetivo, longitud_objetivo); %[cite: 1]
                
                ensayos = {}; %[cite: 1]
                
                for i = 1:length(archivos) %[cite: 1]
                    nombre_archivo = archivos(i).name; %[cite: 1]
                    if ~contains(nombre_archivo, ['Test_' id_probeta '_T']), continue; end %[cite: 1]
                    
                    tokens = regexp(nombre_archivo, '_T(\d+)_([0-9-]+\s+[0-9;]+)\.xlsx', 'tokens'); %[cite: 1]
                    if ~isempty(tokens) %[cite: 1]
                        num_test = str2double(tokens{1}{1}); %[cite: 1]
                        fecha_hora = datetime(strrep(regexprep(tokens{1}{2}, '\s+', ' '), ';', ':'), 'InputFormat', 'yy-MM-dd HH:mm:ss'); %[cite: 1]
                        
                        ruta = fullfile(carpeta_archivos, nombre_archivo); %[cite: 1]
                        
                        df_datos = readtable(ruta, 'Sheet', 'Test_Data');
                        df_sumario = readtable(ruta, 'Sheet', 'Cycle_Summary');
                        
                        n_ciclos = height(df_sumario);
                        t_r0 = zeros(n_ciclos, 1);
                        for c = 1:n_ciclos
                            c_num = df_sumario.Cycle(c);
                            idx_c = find(df_datos.Cycle == c_num, 1, 'first');
                            if ~isempty(idx_c)
                                t_r0(c) = df_datos.Time(idx_c);
                            else
                                t_r0(c) = NaN;
                            end
                        end
                        
                        t_r0 = t_r0(:);
                        drift_r0_col = df_sumario.Drift_R0(:);
                        
                        ensayos{end+1} = struct('num_test', num_test, 'fecha_hora', fecha_hora, ...
                                                'Time', df_datos.Time, 'Resistencia', df_datos.Average_Resistance, ...
                                                'Posicion', df_datos.Position, ...
                                                't_r0', t_r0, 'Drift_R0', drift_r0_col);
                    end
                end
                
                % --- DIBUJAR PANEL 5x1 ---
                figure(fig_res);
                ax = nexttile; %[cite: 1]
                hold on; %[cite: 1]
                
                if isempty(ensayos)
                    text(ax, 0.5, 0.5, ['Sin datos: ', patron], 'Units', 'normalized', 'HorizontalAlignment', 'center');
                    continue; 
                end
                
                hay_datos_totales = true;
                [~, idx] = sort(cellfun(@(x) x.num_test, ensayos)); %[cite: 1]
                ensayos = ensayos(idx); %[cite: 1]
                t0 = ensayos{1}.fecha_hora; %[cite: 1]
                
                all_res = [];
                all_r0 = [];
                
                for j = 1:length(ensayos) %[cite: 1]
                    datos = ensayos{j}; %[cite: 1]
                    t_plot = datos.Time + seconds(datos.fecha_hora - t0); %[cite: 1]
                    
                    plot(ax, t_plot, datos.Resistencia, 'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
                    
                    t_r0_plot = datos.t_r0 + seconds(datos.fecha_hora - t0);
                    plot(ax, t_r0_plot, datos.Drift_R0, 'r.-', 'LineWidth', 1.2, 'MarkerSize', 6);
                    
                    all_res = [all_res; datos.Resistencia];
                    all_r0 = [all_r0; datos.Drift_R0];
                end
                
                grid(ax, 'on'); 
                
                if ~isempty(all_res)
                    min_val = min([all_res; all_r0]);
                    max_val = max([all_res; all_r0]);
                    span = max_val - min_val;
                    if span == 0, span = 50; end
                    ylim(ax, [min_val - span * 0.03, max_val + span * 0.03]);
                end
                
                text(ax, 0.015, 0.82, ['Patrón: ', patron], 'Units', 'normalized', ...
                     'FontWeight', 'bold', 'FontSize', 10, ...
                     'BackgroundColor', [1 1 1 0.75], 'EdgeColor', [0.8 0.8 0.8], ...
                     'Margin', 3);
                 
                hold(ax, 'off');
            end
            
            % Guardar la figura si contiene datos
            if hay_datos_totales
                set(fig_res, 'Visible', 'on'); 
                nombre_archivo_fig = sprintf('Grafica_%s_%s_Probeta_%s.png', grosor_objetivo, longitud_objetivo, numero_probeta);
                saveas(fig_res, fullfile(carpeta_archivos, nombre_archivo_fig));
                fprintf('-> Guardada gráfica: %s\n', nombre_archivo_fig);
            else
                close(fig_res);
            end
            
        end
    end
end

disp('¡Proceso masivo finalizado! Cada figura indica claramente su caso.');