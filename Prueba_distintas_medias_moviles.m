% --- SCRIPT INTERACTIVO PARA FILTRO DE MEDIA MÓVIL ---

% 1. Determinar la ubicación de este script y la ruta relativa a "Datos"
rutaScript = fileparts(mfilename('fullpath'));
rutaPredeterminada = fullfile(rutaScript, '..', 'Datos', '');

% Abrir ventana para seleccionar el archivo Excel
[file, path] = uigetfile('*.xlsx', 'Selecciona el archivo Excel del ensayo', rutaPredeterminada);
if isequal(file, 0)
    disp('Operación cancelada.');
    return;
end
rutaCompleta = fullfile(path, file);

% 2. Leer los datos crudos del Excel
disp('Cargando datos...');
datos = readtable(rutaCompleta, 'Sheet', 'Test_Data');
tiempo = datos.Time;
resistenciaCruda = datos.Resistance;

% 3. Crear la figura y los ejes de la gráfica
fig = figure('Name', 'Analizador Dinámico de Filtro', 'NumberTitle', 'off', 'Color', 'w');

% Ajustamos los ejes para dejar espacio físico al slider en la parte inferior
ax = axes('Parent', fig, 'Position', [0.1, 0.25, 0.85, 0.65]);

% Pintamos el dato crudo (N=1) de fondo en gris claro
plot(ax, tiempo, resistenciaCruda, 'Color', [0.8 0.8 0.8], 'DisplayName', 'Raw Data (Crudo)');
hold(ax, 'on');

% 4. Preparar la línea del filtro dinámico (Arranca en N=10 por defecto)
valorInicial = 10;
filtroInicial = movmean(resistenciaCruda, valorInicial);

% Dibujamos la línea azul que se moverá, y guardamos su referencia en la variable "lineaFiltro"
lineaFiltro = plot(ax, tiempo, filtroInicial, 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Filtro N = %d', valorInicial));
hold(ax, 'off');

% Formato visual de la gráfica
xlabel(ax, 'Time (s)');
ylabel(ax, 'Resistance (Ohms)');
title(ax, 'Ajuste Interactivo de Media Móvil');
legend(ax, 'show', 'Location', 'best');
grid(ax, 'on');

% 5. Crear los controles interactivos (Texto y Slider)

% Texto indicador del valor actual
txtValor = uicontrol('Parent', fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.3, 0.12, 0.4, 0.05], ...
    'String', sprintf('Intervalo del filtro (N): %d', valorInicial), ...
    'BackgroundColor', 'w', 'FontSize', 12, 'FontWeight', 'bold');

% Deslizador (Slider) para barrer de 1 a 100
sliderFiltro = uicontrol('Parent', fig, 'Style', 'slider', 'Units', 'normalized', ...
    'Position', [0.3, 0.05, 0.4, 0.05], ...
    'Min', 1, 'Max', 500, 'Value', valorInicial, ...
    'SliderStep', [1/99, 5/99]); % Incrementos al pinchar las flechas o la barra

% 6. Asignar la función "Callback" al mover el slider
sliderFiltro.Callback = @(src, event) actualizarGrafica(src, txtValor, lineaFiltro, resistenciaCruda);

% Activamos el zoom por defecto
zoom(fig, 'on');
disp('Gráfica interactiva generada. Mueve el deslizador en la parte inferior para ajustar el filtro.');


% =========================================================================
% FUNCIÓN AUXILIAR (Debe ir al final del archivo)
% =========================================================================
% Esta función se dispara automáticamente cada vez que tocas el deslizador
function actualizarGrafica(sliderObj, txtObj, lineaObj, datosCrudos)
    
    % 1. Obtenemos el valor del slider y lo redondeamos a un número entero
    N = round(sliderObj.Value);
    
    % 2. Actualizamos el texto de la interfaz visual
    txtObj.String = sprintf('Intervalo del filtro (N): %d', N);
    
    % 3. Calculamos la nueva media móvil con el valor N actualizado
    datosFiltrados = movmean(datosCrudos, N);
    
    % 4. Re-dibujamos los datos de la línea azul y actualizamos el texto de la leyenda
    lineaObj.YData = datosFiltrados;
    lineaObj.DisplayName = sprintf('Filtro N = %d', N);
end