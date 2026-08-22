% =========================================================================
% SCRIPT: Reparador Masivo por Carpeta (Sin Gauge Factor)
% =========================================================================
clear; clc; close all;

% 1. Selección de carpeta (Única ventana emergente)
rutaCarpeta = uigetdir(pwd, 'Selecciona la CARPETA que contiene los Excels a corregir');

if rutaCarpeta == 0
    disp('Operación cancelada por el usuario.');
    return;
end

% Buscar todos los archivos .xlsx en la carpeta
listaArchivos = dir(fullfile(rutaCarpeta, '*.xlsx'));
total_archivos = length(listaArchivos);

if total_archivos == 0
    disp('ERROR: No se encontraron archivos Excel (.xlsx) en esa carpeta.');
    return;
end

disp('=========================================================');
fprintf('Iniciando escaneo de la carpeta...\n');
fprintf('Se encontraron %d archivo(s) Excel.\n', total_archivos);
disp('Arrancando el servidor de Excel en segundo plano...');
disp('=========================================================');

% 2. Iniciar Excel mediante COM (Totalmente oculto)
try
    Excel = actxserver('Excel.Application');
    Excel.Visible = false; 
    Excel.DisplayAlerts = false; 
catch
    error('CRÍTICO: No se pudo iniciar Excel. Asegúrate de tenerlo cerrado.');
end

% 3. Bucle para procesar cada archivo
for i = 1:total_archivos
    nombreArchivo = listaArchivos(i).name;
    rutaCompleta = fullfile(rutaCarpeta, nombreArchivo);
    
    fprintf('Procesando [%d/%d]: %s\n', i, total_archivos, nombreArchivo);
    
    try
        % Comprobar si es un ensayo dinámico
        hojas = sheetnames(rutaCompleta);
        if ~ismember("Test_Data", hojas)
            disp('   -> [SALTADO] No es un ensayo dinámico (falta la hoja Test_Data).');
            continue;
        end
        
        % Leer los datos numéricos directamente
        datos = readtable(rutaCompleta, 'Sheet', 'Test_Data');
        
        % Comprobar que la tabla no esté vacía
        if isempty(datos)
            disp('   -> [SALTADO] La hoja Test_Data está vacía.');
            continue;
        end
        
        numFilas = height(datos) + 1;
        ciclosEjecutados = max(datos.Cycle);
        
        % ==========================================
        % CÁLCULO INTELIGENTE DE ESCALAS
        % ==========================================
        maxTiempo = max(datos.Time);
        escalaMaxTiempo = maxTiempo * 1.05;
        
        minRes = min(datos.Average_Resistance);
        maxRes = max(datos.Average_Resistance);
        margenRes = (maxRes - minRes) * 0.1;
        if margenRes == 0, margenRes = 50; end
        escalaMinRes = floor((minRes - margenRes) / 10) * 10;
        escalaMaxRes = ceil((maxRes + margenRes) / 10) * 10;

        minPos = min(datos.Position);
        maxPos = max(datos.Position);
        margenPos = (maxPos - minPos) * 0.1;
        if margenPos == 0, margenPos = 100; end
        escalaMinPos = minPos - margenPos;
        escalaMaxPos = maxPos + margenPos;
        
        % ==========================================
        % MODIFICAR EL EXCEL CON COM
        % ==========================================
        Workbook = Excel.Workbooks.Open(rutaCompleta);
        SheetData = Workbook.Sheets.Item('Test_Data');
        
        % Borrar gráficos viejos
        while SheetData.ChartObjects.Count > 0
            SheetData.ChartObjects.Item(1).Delete;
        end
        
        % Gráfico 1: Resistencia vs Tiempo
        Grafico1 = Excel.Charts.Add; Grafico1.ChartType = 'xlXYScatter';
        while Grafico1.SeriesCollection.Count > 0, Grafico1.SeriesCollection.Item(1).Delete; end
        Serie1 = Grafico1.SeriesCollection.NewSeries;
        Serie1.XValues = SheetData.Range(sprintf('D2:D%d', numFilas));
        Serie1.Values = SheetData.Range(sprintf('F2:F%d', numFilas));
        Serie1.MarkerStyle = 8; Serie1.MarkerSize = 2;
        Grafico1.HasTitle = true; Grafico1.ChartTitle.Text = 'Resistance vs Time (Filtered)';
        Grafico1.HasLegend = false;
        Grafico1.Axes(1).HasTitle = true; Grafico1.Axes(1).AxisTitle.Text = 'Time (s)';
        Grafico1.Axes(1).MinimumScale = 0; Grafico1.Axes(1).MaximumScale = escalaMaxTiempo;
        Grafico1.Axes(2).HasTitle = true; Grafico1.Axes(2).AxisTitle.Text = 'Average Resistance (Ohms)';
        Grafico1.Axes(2).MinimumScale = escalaMinRes; Grafico1.Axes(2).MaximumScale = escalaMaxRes;
        Grafico1.Location(2, SheetData.Name);
        Shape1 = SheetData.Shapes.Item(SheetData.Shapes.Count);
        Shape1.Width = 550; Shape1.Height = 350; Shape1.Top = 20; Shape1.Left = 550;
        
        % Gráfico 2: Histéresis
        Grafico2 = Excel.Charts.Add; Grafico2.ChartType = 'xlXYScatterLinesNoMarkers';
        while Grafico2.SeriesCollection.Count > 0, Grafico2.SeriesCollection.Item(1).Delete; end
        for c = 1:ciclosEjecutados
            idx = find(datos.Cycle == c);
            if ~isempty(idx)
                Serie2 = Grafico2.SeriesCollection.NewSeries;
                Serie2.XValues = SheetData.Range(sprintf('F%d:F%d', idx(1)+1, idx(end)+1));
                Serie2.Values = SheetData.Range(sprintf('B%d:B%d', idx(1)+1, idx(end)+1));
                Serie2.Name = sprintf('Cycle %d', c); Serie2.Format.Line.Weight = 1.0;
            end
        end
        Grafico2.HasTitle = true; Grafico2.ChartTitle.Text = 'Hysteresis: Resistance vs Position'; Grafico2.HasLegend = true;
        Grafico2.Axes(1).HasTitle = true; Grafico2.Axes(1).AxisTitle.Text = 'Average Resistance (Ohms)';
        Grafico2.Axes(1).MinimumScale = escalaMinRes; Grafico2.Axes(1).MaximumScale = escalaMaxRes;
        Grafico2.Axes(2).HasTitle = true; Grafico2.Axes(2).AxisTitle.Text = 'Position (Steps)';
        Grafico2.Axes(2).MinimumScale = escalaMinPos; Grafico2.Axes(2).MaximumScale = escalaMaxPos;
        Grafico2.Location(2, SheetData.Name);
        Shape2 = SheetData.Shapes.Item(SheetData.Shapes.Count);
        Shape2.Width = 550; Shape2.Height = 350; Shape2.Top = Shape1.Top + Shape1.Height + 20; Shape2.Left = 550;
        
        % Guardar y cerrar
        Workbook.Save;
        Workbook.Close;
        
        disp('   -> [OK] Gráficos corregidos y guardados.');
        
    catch ME
        disp(['   -> [ERROR] ' ME.message]);
        if exist('Workbook', 'var') && isvalid(Workbook)
            Workbook.Close(false);
        end
    end
end

% 4. Limpieza final
Excel.Quit;
delete(Excel);

disp('=========================================================');
fprintf('¡PROCESO COMPLETADO! (%d archivos escaneados)\n', total_archivos);
disp('=========================================================');