## 16.06.2016 Erivelton Gualter dos Santos <erivelton.gualter@gmail.com>
## Unified Single-Window SISO Tool with Embedded Edit Controller Tab
function GUI_sisotoolv2(varargin)
  global fig1 h1 h2 h3

  graphics_toolkit qt

  % Ensure control package is loaded
  try
    pkg load control;
  catch
    warning('Control package could not be auto-loaded. Make sure it is installed.');
  end_try_catch

  % Initialization of global model parameters
  if isfield(h1, 'G') == 0, h1.G = tf(0.01, [1 12 20]); endif
  if isfield(h1, 'C') == 0, h1.C = zpk([],[],1); endif
  if isfield(h1, 'H') == 0, h1.H = zpk([],[],1); endif
  if isfield(h1, 'F') == 0, h1.F = zpk([],[],1); endif
  if isfield(h1, 'mode') == 0, h1.mode = 'adjust'; endif

  if isfield(h3, 'sys') == 0, h3.sys = h1.C; endif
  if isfield(h3, 'currentzpk') == 0, h3.currentzpk = []; endif

  % 1. Create Single Master Application Window
  fig1 = figure('Name', 'SISO Tool - Control System Designer', ...
                'NumberTitle', 'off', ...
                'Position', [50, 50, 1250, 750], ...
                'CloseRequestFcn', @close_all, ...
                'WindowButtonDownFcn', @down_fig, ...
                'WindowButtonUpFcn', @release_click);

  % Main Response Axes (Top-Left)
  h1.ax1 = axes('Parent', fig1, 'Units', 'normalized', 'Position', [0.05, 0.55, 0.42, 0.38]);

  % Control & Configuration Panel (Bottom-Left)
  ctrl_panel = uipanel('Parent', fig1, 'Title', 'Design Controls', ...
                       'Units', 'normalized', 'Position', [0.05, 0.05, 0.42, 0.46]);

  % Plant Input & Controls
  uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Plant G(s):', ...
            'Units', 'normalized', 'Position', [0.05, 0.83, 0.3, 0.1], 'HorizontalAlignment', 'left');

  h1.enter_plant = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '0.01 / ((s+10)*(s+2))', ...
                             'Units', 'normalized', 'Position', [0.35, 0.83, 0.6, 0.12], ...
                             'BackgroundColor', 'white', 'Callback', @update_plant_cb);

  h1.select_mainaxes = uicontrol('Parent', ctrl_panel, 'Style', 'popupmenu', ...
                                 'Units', 'normalized', 'String', {'Step Response', 'Impulse Response', 'Control Effort'}, ...
                                 'Position', [0.05, 0.66, 0.9, 0.12], 'Callback', @(~,~) plots());

  h1.btn_savecontroller = uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Save Controller', ...
                                    'Units', 'normalized', 'Position', [0.05, 0.48, 0.42, 0.12], 'Callback', @(~,~) call_save_controller());

  h1.btn_editcontroller = uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Edit Controller...', ...
                                    'Units', 'normalized', 'Position', [0.53, 0.48, 0.42, 0.12], 'Callback', @(~,~) switch_tab(4));

  % Wide Gain Slider and Live Text Readout
  uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Gain:', ...
            'Units', 'normalized', 'Position', [0.05, 0.28, 0.12, 0.1], 'HorizontalAlignment', 'left');

  h1.slider_gain = uicontrol('Parent', ctrl_panel, 'Style', 'slider', 'Min', 0.01, 'Max', 100, 'Value', 1, ...
                             'Units', 'normalized', 'Position', [0.18, 0.28, 0.62, 0.1], 'Callback', @slider_adjustgain);

  h1.txt_gain_val = uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', '1.00', ...
                              'Units', 'normalized', 'Position', [0.82, 0.28, 0.13, 0.1], ...
                              'HorizontalAlignment', 'center', 'FontWeight', 'bold');

  % Status Label
  h1.lbl_plant = uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Status: Ready', ...
                           'Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.18], 'HorizontalAlignment', 'left');

  % 2. Native Tab Emulation Buttons at the top right
  uicontrol('Parent', fig1, 'Style', 'pushbutton', 'String', 'Root Locus', ...
            'Units', 'normalized', 'Position', [0.50, 0.93, 0.12, 0.05], 'Callback', @(~,~) switch_tab(1));
  uicontrol('Parent', fig1, 'Style', 'pushbutton', 'String', 'Bode', ...
            'Units', 'normalized', 'Position', [0.62, 0.93, 0.12, 0.05], 'Callback', @(~,~) switch_tab(2));
  uicontrol('Parent', fig1, 'Style', 'pushbutton', 'String', 'Nyquist', ...
            'Units', 'normalized', 'Position', [0.74, 0.93, 0.12, 0.05], 'Callback', @(~,~) switch_tab(3));
  uicontrol('Parent', fig1, 'Style', 'pushbutton', 'String', 'Edit Controller', ...
            'Units', 'normalized', 'Position', [0.86, 0.93, 0.12, 0.05], 'Callback', @(~,~) switch_tab(4));

  % 3. Create Panels for Each Tab Content
  h2.panel_rl    = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'on');
  h2.panel_bode  = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'off');
  h2.panel_nyq   = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'off');
  h2.panel_edit  = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'off');

  % Axes inside graph panels
  h2.axrl = axes('Parent', h2.panel_rl, 'Units', 'normalized', 'Position', [0.12, 0.12, 0.82, 0.82]);

  h2.axbm = axes('Parent', h2.panel_bode, 'Units', 'normalized', 'Position', [0.15, 0.55, 0.8, 0.38]);
  h2.axbp = axes('Parent', h2.panel_bode, 'Units', 'normalized', 'Position', [0.15, 0.10, 0.8, 0.38]);

  h2.axny = axes('Parent', h2.panel_nyq, 'Units', 'normalized', 'Position', [0.12, 0.12, 0.82, 0.82]);

  % Setup Edit Controller Panel UI inside h2.panel_edit
  setup_edit_controller_panel(h2.panel_edit, fig1);

  % 4. Create Toolbar for Root Locus Actions
  setup_toolbar(fig1);

  % Initialize Data and Views
  refresh_all();
endfunction

% --- Setup Edit Controller Panel ---
function setup_edit_controller_panel(parent_panel, fig)
  global h3

  p = uipanel('Parent', parent_panel, 'Title', 'Compensator', 'Units', 'normalized', 'Position', [0.05, 0.68, 0.90, 0.28]);

  h3.select_compensator = uicontrol('Parent', p, 'Style', 'popupmenu', 'Units', 'normalized', ...
                                    'String', {'C', 'F'}, 'Position', [0.05, 0.35, 0.25, 0.35], 'Callback', @call_select);

  uicontrol('Parent', p, 'Style', 'text', 'Units', 'normalized', 'String', ' = ', ...
            'HorizontalAlignment', 'center', 'Position', [0.32, 0.35, 0.08, 0.35]);

  h3.gain_box = uicontrol('Parent', p, 'Style', 'edit', 'Units', 'normalized', 'String', '1', ...
                          'Position', [0.42, 0.35, 0.18, 0.35], 'BackgroundColor', 'white', 'Callback', @call_update_gain);

  % Redundant static 'x' removed here

  h3.lbl_num = uicontrol('Parent', p, 'Style', 'text', 'Units', 'normalized', 'String', '', ...
                         'HorizontalAlignment', 'left', 'Position', [0.62, 0.15, 0.36, 0.7]);

  c3 = uicontextmenu('Parent', fig);
  menu1 = uimenu('Parent', c3, 'Label', 'Add Pole/Zero ...');
  uimenu('Parent', c3, 'Label', 'Delete Pole/Zero ...', 'Callback', @(~,~) delete_pz());

  uimenu('Parent', menu1, 'Label', '''x'' Real Pole', 'Callback', @(~,~) add_rpole());
  uimenu('Parent', menu1, 'Label', '''xx'' Complex Pole', 'Callback', @(~,~) add_cpole());
  uimenu('Parent', menu1, 'Label', '''o'' Real Zero', 'Callback', @(~,~) add_rzero());
  uimenu('Parent', menu1, 'Label', '''oo'' Complex Zero', 'Callback', @(~,~) add_czero());
  uimenu('Parent', menu1, 'Label', 'Integrator', 'Callback', @(~,~) add_integrator());
  uimenu('Parent', menu1, 'Label', 'Differentiator', 'Callback', @(~,~) add_differentiator());

  set(parent_panel, 'UIContextMenu', c3);
endfunction

% --- Tab Switching Callback ---
function switch_tab(tab_idx)
  global h2 h3 h1
  set(h2.panel_rl,   'Visible', 'off');
  set(h2.panel_bode, 'Visible', 'off');
  set(h2.panel_nyq,  'Visible', 'off');
  set(h2.panel_edit, 'Visible', 'off');

  switch tab_idx
    case 1
      set(h2.panel_rl,   'Visible', 'on');
    case 2
      set(h2.panel_bode, 'Visible', 'on');
    case 3
      set(h2.panel_nyq,  'Visible', 'on');
    case 4
      set(h2.panel_edit, 'Visible', 'on');
      h3.sys = h1.C;
      dynamics_panel_refresh();
  endswitch
endfunction

% --- Toolbar Setup Function ---
function setup_toolbar(fig)
  global h2
  t = uitoolbar(fig);

  script_dir = fileparts(mfilename('fullpath'));
  img_dir = fullfile(script_dir, 'images');

  try
    iconrp = im2double(imread(fullfile(img_dir, 'RPole.png')));
    iconrz = im2double(imread(fullfile(img_dir, 'RZero.png')));
    iconcp = im2double(imread(fullfile(img_dir, 'CPole.png')));
    iconcz = im2double(imread(fullfile(img_dir, 'CZero.png')));
    iconer = im2double(imread(fullfile(img_dir, 'Clear_16x16.png')));

    h2.brp = uipushtool(t, 'cdata', iconrp, 'ClickedCallback', @(~,~) call_add_poles());
    h2.brz = uipushtool(t, 'cdata', iconrz, 'ClickedCallback', @(~,~) call_add_zeros());
    h2.bcp = uipushtool(t, 'cdata', iconcp, 'ClickedCallback', @(~,~) call_add_cpoles());
    h2.bcr = uipushtool(t, 'cdata', iconcz, 'ClickedCallback', @(~,~) call_add_czeros());
    h2.ber = uipushtool(t, 'cdata', iconer, 'ClickedCallback', @(~,~) call_delete());
  catch err
    warning(['Could not load toolbar icons from images folder: ', err.message]);
  end_try_catch
endfunction

% --- Toolbar Callbacks ---
function call_add_poles()
  global h1
  h1.mode = 'add_rpole';
endfunction

function call_add_cpoles()
  global h1
  h1.mode = 'add_cpole';
endfunction

function call_add_zeros()
  global h1
  h1.mode = 'add_rzero';
endfunction

function call_add_czeros()
  global h1
  h1.mode = 'add_czero';
endfunction

function call_delete()
  global h1
  h1.mode = 'delete';
endfunction

% --- Mouse Down Interaction on Root Locus ---
function down_fig(~, ~)
  global h1 h2
  if gca ~= h2.axrl
    return;
  endif

  c = get(gca, 'CurrentPoint')([1; 3]);

  if strcmp(h1.mode(1:min(4, length(h1.mode))), 'add_')
    [olpol, olzer, k, ~] = getZP_local(h1.C);

    switch h1.mode
      case 'add_rpole'
        olpol = [olpol; c(1)];
      case 'add_cpole'
        olpol = [olpol; c(1) + 1i*c(2); c(1) - 1i*c(2)];
      case 'add_rzero'
        olzer = [olzer; c(1)];
      case 'add_czero'
        olzer = [olzer; c(1) + 1i*c(2); c(1) - 1i*c(2)];
    endswitch

    h1.C = zpk(olzer, olpol', k);
    h1.mode = 'adjust';
    refresh_all();
  endif
endfunction

% --- Mouse Release Interaction (Dragging / Deleting) ---
function release_click(~, ~)
  global h1 h2
  if gca ~= h2.axrl
    return;
  endif

  c = get(gca, 'CurrentPoint')([1; 3]);
  [olpol, olzer, k, ~] = getZP_local(h1.C);

  poles = [];
  if ~isempty(olpol), poles = [poles, [real(olpol)'; imag(olpol)']]; endif
  if ~isempty(olzer), poles = [poles, [real(olzer)'; imag(olzer)']]; endif

  if isempty(poles)
    return;
  endif

  p = poles - c;
  [~, idx] = min(hypot(p(1, :), p(2, :)));

  if strcmp(h1.mode, 'delete')
    num_poles = length(olpol);

    if abs(poles(2, idx)) > 1e-5
      target_imag = -poles(2, idx);
      target_real = poles(1, idx);
      idxc = find(abs(poles(1, :) - target_real) < 1e-5 & abs(poles(2, :) - target_imag) < 1e-5, 1, 'last');

      if ~isempty(idxc) && idxc ~= idx
        remove_indices = sort([idx, idxc], 'descend');
        for r = remove_indices
          if r <= num_poles
            olpol(r) = [];
            num_poles = num_poles - 1;
          else
            olzer(r - num_poles) = [];
          endif
        endfor
      else
        if idx <= num_poles
          olpol(idx) = [];
        else
          olzer(idx - num_poles) = [];
        endif
      endif
    else
      if idx <= num_poles
        olpol(idx) = [];
      else
        olzer(idx - num_poles) = [];
      endif
    endif

    h1.C = zpk(olzer(:), olpol(:), k);
    h1.mode = 'adjust';
    refresh_all();

  elseif strcmp(h1.mode, 'adjust')
    if abs(poles(2, idx)) > 1e-5
      target_imag = -poles(2, idx);
      target_real = poles(1, idx);
      idxc = find(abs(poles(1, :) - target_real) < 1e-5 & abs(poles(2, :) - target_imag) < 1e-5, 1, 'last');

      poles(1, idx) = c(1);
      poles(2, idx) = c(2);
      if ~isempty(idxc) && idxc ~= idx
        poles(1, idxc) = c(1);
        poles(2, idxc) = -c(2);
      endif
    else
      poles(1, idx) = c(1);
      poles(2, idx) = 0;
    endif

    olpol = poles(1, 1:length(olpol)) + 1i * poles(2, 1:length(olpol));
    olzer = poles(1, length(olpol)+1:end) + 1i * poles(2, length(olpol)+1:end);

    h1.C = zpk(olzer(:), olpol(:), k);
    refresh_all();
  endif
endfunction

% --- Helper to extract ZPK data robustly ---
function [olpol, olzer, k, flag] = getZP_local(sys)
  [num, den] = tfdata(sys, 'vector');
  flag = (length(den) >= 2);
  olpol = roots(den);
  olzer = roots(num);
  [~, ~, k] = zpkdata(sys);
endfunction

% --- Refresh All Views ---
function refresh_all()
  plots();
  plotrlocus();
  plotbode();
  plotnyquist();
  dynamics_panel_refresh();
endfunction

% --- Dynamics Panel Refresh with Non-Overlapping Columns ---
function dynamics_panel_refresh()
  global h1 h2 h3
  if ~isfield(h3, 'sys') || isempty(h3.sys)
    h3.sys = h1.C;
  endif

  if isfield(h3, 'p2') && ishandle(h3.p2)
    delete(h3.p2);
  endif

  h3.p2 = uipanel('Parent', h2.panel_edit, 'Title', 'Dynamics', 'Position', [0.05, 0.05, 0.43, 0.60]);

  uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', 'Type', 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'Position', [0.02 0.82 .24 .1]);
  uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', 'Location', 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Position', [0.28 0.82 .24 .1]);
  uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', 'Damping', 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Position', [0.53 0.82 .20 .1]);
  uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', 'Frequency', 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Position', [0.74 0.82 .24 .1]);

  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  if isfield(h3, 'gain_box') && ishandle(h3.gain_box)
    set(h3.gain_box, 'String', num2str(k));
  endif

  np = length(olpol);
  nz = length(olzer);
  N = np + nz;

  if isfield(h3, 'currentzpk') == 0 || isempty(h3.currentzpk) || h3.currentzpk > N || h3.currentzpk < 1
    h3.currentzpk = [];
  endif

  h3.zpk = zeros(1, max(1, N));
  h3.location = zeros(1, max(1, N));
  h3.damp = zeros(1, max(1, N));
  h3.freq = zeros(1, max(1, N));
  h3.real = zeros(1, max(1, N));
  h3.imag = zeros(1, max(1, N));

  for i = 1:N
    yPos = 0.75 - 0.09 * i;
    is_selected = (!isempty(h3.currentzpk) && h3.currentzpk == i);

    if i <= np
      if imag(olpol(i)) ~= 0
        h3.zpk(i) = uicontrol('Parent', h3.p2, 'Style', 'radiobutton', 'Units', 'normalized', 'String', 'Complex', 'Value', is_selected, 'Callback', @(~,~) select_dynamic(i), 'HorizontalAlignment', 'left', 'Position', [0.02 yPos .26 .08]);
        h3.freq(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', num2str(abs(olpol(i))), 'HorizontalAlignment', 'center', 'Position', [0.74 yPos .24 .08]);
        h3.damp(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', num2str(cos(angle(olpol(i)))), 'HorizontalAlignment', 'center', 'Position', [0.53 yPos .20 .08]);
      else
        h3.zpk(i) = uicontrol('Parent', h3.p2, 'Style', 'radiobutton', 'Units', 'normalized', 'String', 'Real Pole', 'Value', is_selected, 'Callback', @(~,~) select_dynamic(i), 'HorizontalAlignment', 'left', 'Position', [0.02 yPos .26 .08]);
        h3.freq(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', num2str(abs(olpol(i))), 'HorizontalAlignment', 'center', 'Position', [0.74 yPos .24 .08]);
        h3.damp(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', '1', 'HorizontalAlignment', 'center', 'Position', [0.53 yPos .20 .08]);
      endif
      h3.location(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', num2str(olpol(i)), 'HorizontalAlignment', 'center', 'Position', [0.28 yPos .24 .08]);
      h3.real(i) = real(olpol(i));
      h3.imag(i) = imag(olpol(i));
    else
      idx_z = i - np;
      if imag(olzer(idx_z)) ~= 0
        h3.zpk(i) = uicontrol('Parent', h3.p2, 'Style', 'radiobutton', 'Units', 'normalized', 'String', 'Complex', 'Value', is_selected, 'Callback', @(~,~) select_dynamic(i), 'HorizontalAlignment', 'left', 'Position', [0.02 yPos .26 .08]);
        h3.freq(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', num2str(abs(olzer(idx_z))), 'HorizontalAlignment', 'center', 'Position', [0.74 yPos .24 .08]);
        h3.damp(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', num2str(cos(angle(olzer(idx_z)))), 'HorizontalAlignment', 'center', 'Position', [0.53 yPos .20 .08]);
      else
        h3.zpk(i) = uicontrol('Parent', h3.p2, 'Style', 'radiobutton', 'Units', 'normalized', 'String', 'Real Zero', 'Value', is_selected, 'Callback', @(~,~) select_dynamic(i), 'HorizontalAlignment', 'left', 'Position', [0.02 yPos .26 .08]);
        h3.freq(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', num2str(abs(olzer(idx_z))), 'HorizontalAlignment', 'center', 'Position', [0.74 yPos .24 .08]);
        h3.damp(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', '1', 'HorizontalAlignment', 'center', 'Position', [0.53 yPos .20 .08]);
      endif
      h3.location(i) = uicontrol('Parent', h3.p2, 'Style', 'text', 'Units', 'normalized', 'String', num2str(olzer(idx_z)), 'HorizontalAlignment', 'center', 'Position', [0.28 yPos .24 .08]);
      h3.real(i) = real(olzer(idx_z));
      h3.imag(i) = imag(olzer(idx_z));
    endif
  endfor

  [~, ~, k, ~] = getZP_local(h3.sys);
  t = h3.sys/k;
  T = evalc('t'); idx = find(T == "y", 1, 'last'); T(idx:idx+2) = "x  ";
  if isfield(h3, 'lbl_num') && ishandle(h3.lbl_num)
    set(h3.lbl_num, 'String', T(55:end-24));
  endif

  plot_edit_dynamics_panel();
endfunction

function select_dynamic(idx)
  global h3
  [olpol, olzer, ~, ~] = getZP_local(h3.sys);
  N = length(olpol) + length(olzer);
  h3.currentzpk = idx;
  for k = 1:N
    if k == idx
      set(h3.zpk(k), 'Value', 1);
    else
      set(h3.zpk(k), 'Value', 0);
    endif
  endfor
  plot_edit_dynamics_panel();
endfunction

function plot_edit_dynamics_panel()
  global h2 h3
  if isfield(h3, 'p3') && ishandle(h3.p3)
    delete(h3.p3);
  endif

  h3.p3 = uipanel('Parent', h2.panel_edit, 'Title', 'Edit Select Dynamics', 'Position', [0.52, 0.05, 0.43, 0.60]);

  if isempty(h3.currentzpk)
    uicontrol('Parent', h3.p3, 'Style', 'text', 'Units', 'normalized', 'String', 'Select a single row to edit values', 'HorizontalAlignment', 'center', 'Position', [0.1 0.45 .8 .1]);
    return;
  endif

  i = h3.currentzpk;
  str1 = get(h3.zpk(i), 'String');

  if strcmp(str1, 'Complex')
    zpk_cfreq = get(h3.freq(i), 'String');
    zpk_cdamp = get(h3.damp(i), 'String');
    zpk_crpart = num2str(h3.real(i));
    zpk_cipart = num2str(h3.imag(i));

    uicontrol('Parent', h3.p3, 'Style', 'text', 'Units', 'normalized', 'String', 'Natural Frequency', 'HorizontalAlignment', 'left', 'Position', [0.1 0.68 .35 .08]);
    uicontrol('Parent', h3.p3, 'Style', 'text', 'Units', 'normalized', 'String', 'Damping', 'HorizontalAlignment', 'left', 'Position', [0.1 0.50 .35 .08]);
    uicontrol('Parent', h3.p3, 'Style', 'text', 'Units', 'normalized', 'String', 'Real Part', 'HorizontalAlignment', 'left', 'Position', [0.1 0.32 .35 .08]);
    uicontrol('Parent', h3.p3, 'Style', 'text', 'Units', 'normalized', 'String', 'Imaginary Part', 'HorizontalAlignment', 'left', 'Position', [0.1 0.14 .35 .08]);

    h3.enter_cfreq = uicontrol('Parent', h3.p3, 'Style', 'edit', 'Units', 'normalized', 'String', zpk_cfreq, 'Callback', @call_update_dynamic, 'Position', [0.55 0.68 .35 0.08], 'BackgroundColor', 'white');
    h3.enter_cdamp = uicontrol('Parent', h3.p3, 'Style', 'edit', 'Units', 'normalized', 'String', zpk_cdamp, 'Callback', @call_update_dynamic, 'Position', [0.55 0.50 .35 0.08], 'BackgroundColor', 'white');
    h3.enter_crpart = uicontrol('Parent', h3.p3, 'Style', 'edit', 'Units', 'normalized', 'String', zpk_crpart, 'Callback', @call_update_dynamic, 'Position', [0.55 0.32 .35 0.08], 'BackgroundColor', 'white');
    h3.enter_cipart = uicontrol('Parent', h3.p3, 'Style', 'edit', 'Units', 'normalized', 'String', zpk_cipart, 'Callback', @call_update_dynamic, 'Position', [0.55 0.14 .35 0.08], 'BackgroundColor', 'white');
  else
    uicontrol('Parent', h3.p3, 'Style', 'text', 'Units', 'normalized', 'String', 'Location', 'HorizontalAlignment', 'left', 'Position', [0.1 0.45 .35 .08]);
    h3.enter_rlocation = uicontrol('Parent', h3.p3, 'Style', 'edit', 'Units', 'normalized', 'String', get(h3.location(i), 'String'), 'Callback', @call_update_dynamic, 'Position', [0.55 0.45 .35 0.08], 'BackgroundColor', 'white');
  endif
endfunction

function call_select(~, ~)
  global h1 h3
  if get(h3.select_compensator, 'Value') == 2
    h3.sys = h1.F;
  else
    h3.sys = h1.C;
  endif
  h3.currentzpk = [];
  dynamics_panel_refresh();
endfunction

function update_active_sys()
  global h1 h3
  if isfield(h3, 'select_compensator') && ishandle(h3.select_compensator)
    if get(h3.select_compensator, 'Value') == 2
      h1.F = h3.sys;
    else
      h1.C = h3.sys;
    endif
  else
    h1.C = h3.sys;
  endif
endfunction

function call_update_gain(~, ~)
  global h3
  [z, p, ~] = zpkdata(h3.sys);
  k = get(h3.gain_box, 'String');
  h3.sys = zpk(z, p, str2num(k));
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

function call_update_dynamic(~, ~)
  global h3
  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  np = length(olpol);
  nz = length(olzer);
  ii = h3.currentzpk;
  if isempty(ii)
    return;
  endif

  imag_flag = 0;
  if np > 0 && ii <= np
    if imag(olpol(ii)) ~= 0
      imag_flag = 1;
    else
      olpol(ii) = str2num(get(h3.enter_rlocation, 'String'));
    endif
  endif

  if nz > 0 && ii > np
    if imag(olzer(ii-np)) ~= 0
      imag_flag = 1;
    else
      olzer(ii-np) = str2num(get(h3.enter_rlocation, 'String'));
    endif
  endif

  if imag_flag
    c(1) = str2num(get(h3.enter_crpart, 'String'));
    c(2) = str2num(get(h3.enter_cipart, 'String'));
    target_imag = h3.imag(ii);

    for idx = 1:length(olpol)
      if abs(imag(olpol(idx)) - target_imag) < 1e-5
        olpol(idx) = c(1) + 1i * c(2);
      elseif abs(imag(olpol(idx)) + target_imag) < 1e-5
        olpol(idx) = c(1) - 1i * c(2);
      endif
    endfor

    for idx = 1:length(olzer)
      if abs(imag(olzer(idx)) - target_imag) < 1e-5
        olzer(idx) = c(1) + 1i * c(2);
      elseif abs(imag(olzer(idx)) + target_imag) < 1e-5
        olzer(idx) = c(1) - 1i * c(2);
      endif
    endfor
  endif

  h3.sys = zpk(olzer(:), olpol(:), k);
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

function add_rpole()
  global h3
  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  olpol = [olpol(:); -1];
  h3.sys = zpk(olzer(:), olpol, k);
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

function add_cpole()
  global h3
  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  olpol = [olpol(:); -1+1i; -1-1i];
  h3.sys = zpk(olzer(:), olpol, k);
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

function add_rzero()
  global h3
  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  olzer = [olzer(:); -1];
  h3.sys = zpk(olzer, olpol(:), k);
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

function add_czero()
  global h3
  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  olzer = [olzer(:); -1+1i; -1-1i];
  h3.sys = zpk(olzer, olpol(:), k);
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

function add_integrator()
  global h3
  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  olpol = [olpol(:); 0];
  h3.sys = zpk(olzer(:), olpol, k);
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

function add_differentiator()
  global h3
  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  olzer = [olzer(:); 0];
  h3.sys = zpk(olzer, olpol(:), k);
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

function delete_pz()
  global h3
  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  poles(1, :) = [real(olpol)', real(olzer)'];
  poles(2, :) = [imag(olpol)', imag(olzer)'];

  idx = h3.currentzpk;
  if isempty(idx)
    return;
  endif

  num_poles = length(olpol);
  if abs(poles(2, idx)) > 1e-5
    target_imag = -poles(2, idx);
    target_real = poles(1, idx);
    idxc = find(abs(poles(1, :) - target_real) < 1e-5 & abs(poles(2, :) - target_imag) < 1e-5, 1, 'last');

    if ~isempty(idxc) && idxc ~= idx
      remove_indices = sort([idx, idxc], 'descend');
      for r = remove_indices
        if r <= num_poles
          olpol(r) = [];
          num_poles = num_poles - 1;
        else
          olzer(r - num_poles) = [];
        endif
      endfor
    else
      if idx <= num_poles
        olpol(idx) = [];
      else
        olzer(idx - num_poles) = [];
      endif
    endif
  else
    if idx <= num_poles
      olpol(idx) = [];
    else
      olzer(idx - num_poles) = [];
    endif
  endif

  h3.sys = zpk(olzer, olpol', k);
  update_active_sys();
  h3.currentzpk = [];
  dynamics_panel_refresh();
  refresh_all();
endfunction

% --- Callbacks & Updates ---
function update_plant_cb(src, ~)
  global h1
  v = get(src, 'String');
  try
    s = tf('s');
    h1.G = eval(v);
    set(h1.lbl_plant, 'String', 'Status: Plant updated successfully.');
    refresh_all();
  catch err
    set(h1.lbl_plant, 'String', ['Status Error: ', err.message]);
    errordlg(['Invalid Transfer Function syntax: ', err.message], 'Syntax Error');
  end_try_catch
endfunction

function slider_adjustgain(src, ~)
  global h1
  k = get(src, 'Value');
  [z, p, ~] = zpkdata(h1.C);
  h1.C = zpk(z, p, k);

  if isfield(h1, 'txt_gain_val') && ishandle(h1.txt_gain_val)
    set(h1.txt_gain_val, 'String', num2str(k, '%.2f'));
  endif
  refresh_all();
endfunction

function plots()
  global h1
  axes(h1.ax1); cla;
  C = h1.C;
  u = C / (1 + C * h1.G * h1.H);

  choice = get(h1.select_mainaxes, 'Value');
  switch choice
    case 1
      step(feedback(C * h1.G, h1.H));
      title('Closed-Loop Step Response');
    case 2
      impulse(feedback(C * h1.G, h1.H));
      title('Closed-Loop Impulse Response');
    case 3
      step(u);
      title('Control Effort Response');
  endswitch
endfunction

function plotrlocus()
  global h1 h2
  axes(h2.axrl); cla;
  try
    rlocus(h1.G * h1.C);
    title('Root Locus Diagram');

    [olpol, olzer, ~] = getZP_local(h1.C);
    if ~isempty(olpol)
      hold on; plot(real(olpol), imag(olpol), 'x', 'markersize', 8, 'color', 'magenta', 'linewidth', 2); hold off;
    endif
    if ~isempty(olzer)
      hold on; plot(real(olzer), imag(olzer), 'o', 'markersize', 8, 'color', 'magenta', 'linewidth', 2); hold off;
    endif
  catch
  end_try_catch
endfunction

function plotbode()
  global h1 h2
  axes(h2.axbm); cla(h2.axbm);
  axes(h2.axbp); cla(h2.axbp);
  try
    [mag, phase, w] = bode(h1.G * h1.C);
    semilogx(h2.axbm, w, mag2db(squeeze(mag))); grid(h2.axbm, 'on');
    ylabel(h2.axbm, 'Magnitude (dB)');
    title(h2.axbm, 'Open-Loop Bode Diagram');

    semilogx(h2.axbp, w, squeeze(phase)); grid(h2.axbp, 'on');
    xlabel(h2.axbp, 'Frequency (rad/s)');
    ylabel(h2.axbp, 'Phase (deg)');
  catch
  end_try_catch
endfunction

function plotnyquist()
  global h1 h2
  axes(h2.axny); cla;
  try
    nyquist(h1.G * h1.C);
    title('Nyquist Diagram');
  catch
  end_try_catch
endfunction

function call_save_controller()
  global h1
  C = h1.C;
  save('controller.mat', 'C');
  disp('Controller saved to controller.mat');
endfunction

function close_all(varargin)
  close all force;
  clear all global;
endfunction
