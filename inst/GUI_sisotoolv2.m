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
  if isfield(h1, 'G_str') == 0, h1.G_str = '0.01 / ((s+10)*(s+2))'; endif
  if isfield(h1, 'C') == 0, h1.C = zpk([],[],1); endif
  if isfield(h1, 'H') == 0, h1.H = zpk([],[],1); endif
  if isfield(h1, 'F') == 0, h1.F = zpk([],[],1); endif
  if isfield(h1, 'architecture_idx') == 0, h1.architecture_idx = 1; endif
  if isfield(h1, 'mode') == 0, h1.mode = 'adjust'; endif

  % Register refresh callback for cross-file communication
  h1.refresh_cb = @refresh_all;

  if isfield(h3, 'sys') == 0, h3.sys = h1.C; endif
  if isfield(h3, 'currentzpk') == 0, h3.currentzpk = []; endif

  % 1. Create Single Master Application Window
  fig1 = figure('Name', 'SISO Tool - Control System Designer', ...
                'NumberTitle', 'off', ...
                'Position', [50, 50, 1250, 780], ...
                'CloseRequestFcn', @close_all, ...
                'WindowButtonDownFcn', @down_fig, ...
                'WindowButtonUpFcn', @release_click);

  % Main Response Axes (Top-Left)
  h1.ax1 = axes('Parent', fig1, 'Units', 'normalized', 'Position', [0.05, 0.55, 0.42, 0.38]);

  % Control & Configuration Panel (Bottom-Left)
  ctrl_panel = uipanel('Parent', fig1, 'Title', 'Design Controls', ...
                       'Units', 'normalized', 'Position', [0.05, 0.02, 0.42, 0.50]);

  % Plant Input & Controls
  uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Plant G(s):', ...
            'Units', 'normalized', 'Position', [0.05, 0.88, 0.25, 0.08], 'HorizontalAlignment', 'left');

  h1.enter_plant = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '0.01 / ((s+10)*(s+2))', ...
                             'Units', 'normalized', 'Position', [0.32, 0.87, 0.63, 0.09], ...
                             'BackgroundColor', 'white', 'Callback', @update_plant_cb);

  h1.select_mainaxes = uicontrol('Parent', ctrl_panel, 'Style', 'popupmenu', ...
                                 'Units', 'normalized', 'String', {'Step Response', 'Impulse Response', 'Control Effort'}, ...
                                 'Position', [0.05, 0.76, 0.9, 0.09], 'Callback', @(~,~) plots());

  h1.btn_savecontroller = uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Save Controller', ...
                                    'Units', 'normalized', 'Position', [0.05, 0.65, 0.28, 0.09], 'Callback', @(~,~) call_save_controller());

  h1.btn_editcontroller = uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Edit Controller', ...
                                    'Units', 'normalized', 'Position', [0.36, 0.65, 0.28, 0.09], 'Callback', @(~,~) switch_tab(5));

  h1.btn_editarchitecture = uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Architecture...', ...
                                    'Units', 'normalized', 'Position', [0.67, 0.65, 0.28, 0.09], 'Callback', @(~,~) call_menuarchitecture());

  % Saved Designs Listbox (Click to toggle Active/Hidden)
  uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Saved Designs (Click to Toggle):', ...
            'Units', 'normalized', 'Position', [0.05, 0.53, 0.9, 0.08], 'HorizontalAlignment', 'left');

  h1.design_listbox = uicontrol('Parent', ctrl_panel, 'Style', 'listbox', ...
                                'Units', 'normalized', 'String', {'(No saved designs yet)'}, ...
                                'Position', [0.05, 0.29, 0.9, 0.22], ...
                                'BackgroundColor', 'white', 'Callback', @toggle_design_cb);

  % Delete Design Button
  h1.btn_deletedesign = uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Delete Selected Design', ...
                                    'Units', 'normalized', 'Position', [0.05, 0.19, 0.9, 0.08], 'Callback', @delete_design_cb);

  % Architecture Status Indicator Label
  h1.lbl_arch_status = uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Architecture: Config 1', ...
                                 'Units', 'normalized', 'Position', [0.05, 0.11, 0.45, 0.07], ...
                                 'HorizontalAlignment', 'left', 'FontWeight', 'bold', 'ForegroundColor', [0 0.4 0.8]);

  % Wide Gain Slider and Live Text Readout
  uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Gain:', ...
            'Units', 'normalized', 'Position', [0.05, 0.03, 0.12, 0.07], 'HorizontalAlignment', 'left');

  h1.slider_gain = uicontrol('Parent', ctrl_panel, 'Style', 'slider', 'Min', 0.01, 'Max', 100, 'Value', 1, ...
                             'Units', 'normalized', 'Position', [0.18, 0.03, 0.52, 0.07], 'Callback', @slider_adjustgain);

  h1.txt_gain_val = uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', '1.00', ...
                              'Units', 'normalized', 'Position', [0.72, 0.03, 0.22, 0.07], ...
                              'HorizontalAlignment', 'center', 'FontWeight', 'bold');

  % 2. Native Tab Emulation Buttons at the top right
  uicontrol('Parent', fig1, 'Style', 'pushbutton', 'String', 'Root Locus', ...
            'Units', 'normalized', 'Position', [0.50, 0.93, 0.12, 0.05], 'Callback', @(~,~) switch_tab(1));
  uicontrol('Parent', fig1, 'Style', 'pushbutton', 'String', 'Bode', ...
            'Units', 'normalized', 'Position', [0.62, 0.93, 0.12, 0.05], 'Callback', @(~,~) switch_tab(2));
  uicontrol('Parent', fig1, 'Style', 'pushbutton', 'String', 'Nyquist', ...
            'Units', 'normalized', 'Position', [0.74, 0.93, 0.12, 0.05], 'Callback', @(~,~) switch_tab(3));
  uicontrol('Parent', fig1, 'Style', 'pushbutton', 'String', 'All Plots', ...
            'Units', 'normalized', 'Position', [0.86, 0.93, 0.12, 0.05], 'Callback', @(~,~) switch_tab(4));

  % 3. Create Panels for Each Tab Content
  h2.panel_rl    = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'on');
  h2.panel_bode  = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'off');
  h2.panel_nyq   = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'off');
  h2.panel_all   = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'off');
  h2.panel_edit  = uipanel('Parent', fig1, 'Units', 'normalized', 'Position', [0.50, 0.05, 0.48, 0.87], 'Visible', 'off');

  % Axes inside single graph panels
  h2.axrl = axes('Parent', h2.panel_rl, 'Units', 'normalized', 'Position', [0.12, 0.12, 0.82, 0.82]);

  h2.axbm = axes('Parent', h2.panel_bode, 'Units', 'normalized', 'Position', [0.15, 0.55, 0.8, 0.38]);
  h2.axbp = axes('Parent', h2.panel_bode, 'Units', 'normalized', 'Position', [0.15, 0.10, 0.8, 0.38]);

  h2.axny = axes('Parent', h2.panel_nyq, 'Units', 'normalized', 'Position', [0.12, 0.12, 0.82, 0.82]);

  % Statically create 2x2 grid axes for All Plots panel
  h2.ax_all_rl = axes('Parent', h2.panel_all, 'Units', 'normalized', 'Position', [0.08, 0.55, 0.38, 0.38]);
  h2.ax_all_bm = axes('Parent', h2.panel_all, 'Units', 'normalized', 'Position', [0.55, 0.55, 0.42, 0.38]);
  h2.ax_all_ny = axes('Parent', h2.panel_all, 'Units', 'normalized', 'Position', [0.08, 0.10, 0.38, 0.38]);
  h2.ax_all_bp = axes('Parent', h2.panel_all, 'Units', 'normalized', 'Position', [0.55, 0.10, 0.42, 0.38]);

  % Setup Edit Controller Panel UI inside h2.panel_edit
  setup_edit_controller_panel(h2.panel_edit, fig1);

  % 4. Create Toolbar for Root Locus Actions
  setup_toolbar(fig1);

  % Initialize Data and Views
  refresh_all();
endfunction

% --- Dynamic System Evaluator for All 6 Architectures ---
function [sys_ol, sys_cl] = get_active_system_eval(C_override)
  global h1
  if ~isfield(h1, 'architecture_idx') || isempty(h1.architecture_idx)
    h1.architecture_idx = 1;
  endif
  cfg = h1.architecture_idx;

  F  = get_b(h1, 'F', 1);
  if nargin > 0 && ~isempty(C_override)
    C = C_override;
  else
    C = get_b(h1, 'C', 1);
  endif
  C1 = get_b(h1, 'C1', 1);
  C2 = get_b(h1, 'C2', 1);
  G  = get_b(h1, 'G', 1);
  G1 = get_b(h1, 'G1', 1);
  G2 = get_b(h1, 'G2', 1);
  Gd = get_b(h1, 'Gd', 1);
  H  = get_b(h1, 'H', 1);
  H1 = get_b(h1, 'H1', 1);
  H2 = get_b(h1, 'H2', 1);

  % Ensure all components are valid LTI objects to prevent feedback() errors
  if isa(F, 'double'), F = tf(F); endif
  if isa(C, 'double'), C = tf(C); endif
  if isa(C1, 'double'), C1 = tf(C1); endif
  if isa(C2, 'double'), C2 = tf(C2); endif
  if isa(G, 'double'), G = tf(G); endif
  if isa(G1, 'double'), G1 = tf(G1); endif
  if isa(G2, 'double'), G2 = tf(G2); endif
  if isa(Gd, 'double'), Gd = tf(Gd); endif
  if isa(H, 'double'), H = tf(H); endif
  if isa(H1, 'double'), H1 = tf(H1); endif
  if isa(H2, 'double'), H2 = tf(H2); endif

  switch cfg
    case 1
      sys_ol = C * G * H;
      sys_cl = feedback(F * C * G, H);
    case 2
      sys_ol = G * C * H;
      sys_cl = feedback(F * G, C * H);
    case 3
      sys_ol = C * G * H;
      sys_cl = feedback(F * G, C * H);
    case 4
      sys_ol = C1 * C2 * G * H;
      sys_cl = feedback(F * C1 * C2 * G, H);
    case 5
      sys_ol = C * (G1 + G2);
      sys_cl = feedback(F * C * (G1 + G2), tf(1));
    case 6
      sys_ol = C1 * G1 * H1;
      sys_cl = feedback(F * C1 * G1, H1);
    otherwise
      sys_ol = C * G * H;
      sys_cl = feedback(F * C * G, H);
  endswitch
endfunction

function val = get_b(h, name, default_val)
  if isfield(h, name) && ~isempty(h.(name))
    val = h.(name);
  else
    val = default_val;
  endif
endfunction

% --- Setup Edit Controller Panel ---
function setup_edit_controller_panel(parent_panel, fig)
  global h3

  p = uipanel('Parent', parent_panel, 'Title', 'Compensator', 'Units', 'normalized', 'Position', [0.05, 0.68, 0.90, 0.28]);

  h3.select_compensator = uicontrol('Parent', p, 'Style', 'popupmenu', 'Units', 'normalized', ...
                                    'String', {'C', 'F'}, 'Position', [0.03, 0.35, 0.10, 0.35], 'Callback', @call_select);

  uicontrol('Parent', p, 'Style', 'text', 'Units', 'normalized', 'String', ' = ', ...
            'HorizontalAlignment', 'center', 'Position', [0.14, 0.35, 0.04, 0.35]);

  h3.gain_box = uicontrol('Parent', p, 'Style', 'edit', 'Units', 'normalized', 'String', '1', ...
                          'Position', [0.19, 0.35, 0.24, 0.35], 'BackgroundColor', 'white', 'Callback', @call_update_gain);

  uicontrol('Parent', p, 'Style', 'text', 'Units', 'normalized', 'String', ' x ', ...
            'HorizontalAlignment', 'center', 'Position', [0.44, 0.35, 0.04, 0.35]);

  h3.lbl_num = uicontrol('Parent', p, 'Style', 'text', 'Units', 'normalized', 'String', '', ...
                         'HorizontalAlignment', 'left', 'Position', [0.50, 0.15, 0.48, 0.7]);

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
  set(h2.panel_all,  'Visible', 'off');
  set(h2.panel_edit, 'Visible', 'off');

  switch tab_idx
    case 1
      set(h2.panel_rl,   'Visible', 'on');
    case 2
      set(h2.panel_bode, 'Visible', 'on');
    case 3
      set(h2.panel_nyq,  'Visible', 'on');
    case 4
      set(h2.panel_all,  'Visible', 'on');
      plot_all();
    case 5
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
  if gca ~= h2.axrl && gca ~= h2.ax_all_rl
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
  if gca ~= h2.axrl && gca ~= h2.ax_all_rl
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
      end
    else
      if idx <= num_poles
        olpol(idx) = [];
      else
        olzer(idx - num_poles) = [];
      endif
    end

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

% --- Update Slider Max Limit Callback ---
function update_max_gain_cb(src, ~)
  global h1
  new_max = str2num(get(src, 'String'));

  if ~isempty(new_max) && new_max > 0
    current_val = get(h1.slider_gain, 'Value');

    if current_val > new_max
      set(h1.slider_gain, 'Value', new_max);
    endif

    set(h1.slider_gain, 'Max', new_max);

    [~, ~, k] = zpkdata(h1.C);
    if k > new_max
      k = new_max;
      [z, p, ~] = zpkdata(h1.C);
      h1.C = zpk(z, p, k);
    endif

    set(h1.slider_gain, 'Value', k);
    if isfield(h1, 'txt_gain_val') && ishandle(h1.txt_gain_val)
      set(h1.txt_gain_val, 'String', num2str(k, '%.2f'));
    endif
    refresh_all();
  else
    set(src, 'String', num2str(get(h1.slider_gain, 'Max')));
    errordlg('Please enter a valid positive number for the maximum gain.', 'Invalid Input');
  endif
endfunction

% --- Toggle Design Visibility Callback ---
function toggle_design_cb(~, ~)
  global h1
  if isfield(h1, 'list_num') && ~isempty(h1.list_num)
    idx = get(h1.design_listbox, 'Value');
    if idx >= 1 && idx <= length(h1.flag_disp_C)
      if h1.flag_disp_C(idx) == 1
        h1.flag_disp_C(idx) = 0;
      else
        h1.flag_disp_C(idx) = 1;
      endif
      update_design_listbox_strings();
      plots();
    endif
  endif
endfunction

% --- Delete Selected Design Callback ---
function delete_design_cb(~, ~)
  global h1
  if isfield(h1, 'list_num') && ~isempty(h1.list_num)
    idx = get(h1.design_listbox, 'Value');
    if idx >= 1 && idx <= length(h1.list_num)
      h1.list_num(idx) = [];
      h1.list_den(idx) = [];
      h1.flag_disp_C(idx) = [];

      if isempty(h1.list_num)
        set(h1.design_listbox, 'String', {'(No saved designs yet)'}, 'Value', 1);
        if isfield(h1, 'flag_disp_C'), h1 = rmfield(h1, 'flag_disp_C'); endif
      else
        if idx > length(h1.list_num)
          set(h1.design_listbox, 'Value', length(h1.list_num));
        endif
        update_design_listbox_strings();
      endif

      plots();
      set(h1.lbl_plant, 'String', 'Status: Design deleted.');
    endif
  else
    errordlg('No saved designs available to delete.', 'Warning');
  endif
endfunction

function update_design_listbox_strings()
  global h1
  if isfield(h1, 'list_num') && ~isempty(h1.list_num)
    n = length(h1.list_num);
    str_cell = cell(n, 1);
    for i = 1:n
      if h1.flag_disp_C(i) == 1
        str_cell{i} = sprintf('Design %d [Active]', i);
      else
        str_cell{i} = sprintf('Design %d [Hidden]', i);
      endif
    endfor
    set(h1.design_listbox, 'String', str_cell);
  endif
endfunction

% --- Refresh All Views ---
function refresh_all()
  global h1 h2 h3
  if isfield(h3, 'select_compensator') && ishandle(h3.select_compensator)
    if get(h3.select_compensator, 'Value') == 1
      h3.sys = h1.C;
    endif
  else
    h3.sys = h1.C;
  endif

  plots();
  plotrlocus(h2.axrl);
  plotbode(h2.axbm, h2.axbp);
  plotnyquist(h2.axny);

  if isfield(h2, 'panel_all') && ishandle(h2.panel_all) && strcmp(get(h2.panel_all, 'Visible'), 'on')
    plot_all();
  endif
  dynamics_panel_refresh();
endfunction

% --- Dynamics Panel Refresh (Full-Width Editable Table) ---
function dynamics_panel_refresh()
  global h1 h2 h3

  % Determine valid compensator options based on active architecture
  cfg = get_arch_idx();
  switch cfg
    case {1, 2, 3}
      comp_str = {'C', 'F'};
    case 4
      comp_str = {'C1', 'C2'};
    case 5
      comp_str = {'C', 'F'};
    case 6
      comp_str = {'C1', 'C2', 'F'};
    otherwise
      comp_str = {'C', 'F'};
  endswitch

  if isfield(h3, 'select_compensator') && ishandle(h3.select_compensator)
    set(h3.select_compensator, 'String', comp_str);
    if get(h3.select_compensator, 'Value') > length(comp_str)
      set(h3.select_compensator, 'Value', 1);
    endif

    val = get(h3.select_compensator, 'Value');
    selected_comp = comp_str{val};
    switch selected_comp
      case 'C'
        if ~isfield(h1, 'C'), h1.C = zpk([],[],1); endif
        h3.sys = h1.C;
      case 'C1'
        if ~isfield(h1, 'C1'), h1.C1 = zpk([],[],1); endif
        h3.sys = h1.C1;
      case 'C2'
        if ~isfield(h1, 'C2'), h1.C2 = zpk([],[],1); endif
        h3.sys = h1.C2;
      case 'F'
        if ~isfield(h1, 'F'), h1.F = zpk([],[],1); endif
        h3.sys = h1.F;
    endswitch
  else
    if ~isfield(h3, 'sys') || isempty(h3.sys)
      h3.sys = h1.C;
    endif
  endif

  if ~isfield(h3, 'sys') || isempty(h3.sys)
    h3.sys = h1.C;
  endif

  if isfield(h3, 'p2') && ishandle(h3.p2), delete(h3.p2); endif
  if isfield(h3, 'p3') && ishandle(h3.p3), delete(h3.p3); endif

  h3.p2 = uipanel('Parent', h2.panel_edit, 'Title', 'Compensator Dynamics (Double-click Location to Edit)', 'Position', [0.05, 0.05, 0.90, 0.60]);

  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  if isfield(h3, 'gain_box') && ishandle(h3.gain_box)
    set(h3.gain_box, 'String', num2str(k));
  endif

  np = length(olpol);
  nz = length(olzer);
  N = np + nz;

  table_data = cell(max(1, N), 4);

  if N == 0
    table_data = {'(None)', '', '', ''};
  else
    for i = 1:N
      if i <= np
        val = olpol(i);
        if imag(val) ~= 0
          t_str = 'Complex Pole';
          d_val = num2str(cos(angle(val)));
        else
          t_str = 'Real Pole';
          d_val = '1';
        endif
      else
        idx_z = i - np;
        val = olzer(idx_z);
        if imag(val) ~= 0
          t_str = 'Complex Zero';
          d_val = num2str(cos(angle(val)));
        else
          t_str = 'Real Zero';
          d_val = '1';
        endif
      endif

      table_data{i, 1} = t_str;
      table_data{i, 2} = num2str(val);
      table_data{i, 3} = d_val;
      table_data{i, 4} = num2str(abs(val));
    endfor
  endif

  col_width_cell = {110, 130, 85, 85};
  headers = {'Type', 'Location', 'Damping', 'Frequency'};

  h3.table = uitable('Parent', h3.p2, ...
                     'Units', 'normalized', ...
                     'Position', [0.03, 0.05, 0.94, 0.90], ...
                     'Data', table_data, ...
                     'ColumnName', headers, ...
                     'ColumnWidth', col_width_cell, ...
                     'ColumnEditable', [false, true, false, false], ...
                     'CellEditCallback', @table_edit_cb);

  [z, p, ~] = zpkdata(h3.sys, 'v');
  if isempty(z) && isempty(p)
    T_clean = '1';
  else
    [num, den] = tfdata(h3.sys/k, 'v');
    num_str = poly2str_custom(num);
    den_str = poly2str_custom(den);

    max_len = max(length(num_str), length(den_str));
    dash_str = repmat('-', 1, max_len);

    if length(num_str) < max_len
      pad = repmat(' ', 1, floor((max_len - length(num_str))/2));
      num_str = [pad, num_str];
    endif
    if length(den_str) < max_len
      pad = repmat(' ', 1, floor((max_len - length(den_str))/2));
      den_str = [pad, den_str];
    endif

    T_clean = sprintf('%s\n%s\n%s', num_str, dash_str, den_str);
  endif

  if isfield(h3, 'lbl_num') && ishandle(h3.lbl_num)
    set(h3.lbl_num, 'String', T_clean);
  endif
endfunction

% --- Table Cell Edit Callback (Inline Editing) ---
function table_edit_cb(~, event)
  global h3
  row = event.Indices(1, 1);
  new_val_str = event.NewData;

  [olpol, olzer, k, ~] = getZP_local(h3.sys);
  np = length(olpol);

  new_val = str2num(new_val_str);
  if isempty(new_val)
    errordlg('Please enter a valid numeric value or complex expression (e.g., -2+3i).', 'Invalid Input');
    dynamics_panel_refresh();
    return;
  endif

  if row <= np
    old_val = olpol(row);
    olpol(row) = new_val;
    if imag(old_val) ~= 0 && imag(new_val) ~= 0
      target_imag = -imag(old_val);
      target_real = real(old_val);
      for idx = 1:np
        if abs(real(olpol(idx)) - target_real) < 1e-5 && abs(imag(olpol(idx)) - target_imag) < 1e-5
          olpol(idx) = real(new_val) - 1i * imag(new_val);
        endif
      endfor
    endif
  else
    idx_z = row - np;
    old_val = olzer(idx_z);
    olzer(idx_z) = new_val;
    if imag(old_val) ~= 0 && imag(new_val) ~= 0
      target_imag = -imag(old_val);
      target_real = real(old_val);
      for idx = 1:length(olzer)
        if abs(real(olzer(idx)) - target_real) < 1e-5 && abs(imag(olzer(idx)) - target_imag) < 1e-5
          olzer(idx) = real(new_val) - 1i * imag(new_val);
        endif
      endfor
    endif
  endif

  h3.sys = zpk(olzer(:), olpol(:), k);
  update_active_sys();
  dynamics_panel_refresh();
  refresh_all();
endfunction

% --- Compensator Selection Callback ---
function call_select(~, ~)
  global h1 h3
  if isfield(h3, 'select_compensator') && ishandle(h3.select_compensator)
    val = get(h3.select_compensator, 'Value');
    str_list = get(h3.select_compensator, 'String');
    if iscell(str_list)
      selected_comp = str_list{val};
    else
      selected_comp = str_list;
    endif

    switch selected_comp
      case 'C'
        if ~isfield(h1, 'C'), h1.C = zpk([],[],1); endif
        h3.sys = h1.C;
      case 'C1'
        if ~isfield(h1, 'C1'), h1.C1 = zpk([],[],1); endif
        h3.sys = h1.C1;
      case 'C2'
        if ~isfield(h1, 'C2'), h1.C2 = zpk([],[],1); endif
        h3.sys = h1.C2;
      case 'F'
        if ~isfield(h1, 'F'), h1.F = zpk([],[],1); endif
        h3.sys = h1.F;
      otherwise
        h3.sys = h1.C;
    endswitch
  endif
  h3.currentzpk = [];
  dynamics_panel_refresh();
endfunction

% --- Sync Active System Back to Global Workspace ---
function update_active_sys()
  global h1 h3
  if isfield(h3, 'select_compensator') && ishandle(h3.select_compensator)
    val = get(h3.select_compensator, 'Value');
    str_list = get(h3.select_compensator, 'String');
    if iscell(str_list)
      selected_comp = str_list{val};
    else
      selected_comp = str_list;
    endif

    switch selected_comp
      case 'C'
        h1.C = h3.sys;
      case 'C1'
        h1.C1 = h3.sys;
      case 'C2'
        h1.C2 = h3.sys;
      case 'F'
        h1.F = h3.sys;
    endswitch
  else
    h1.C = h3.sys;
  endif
endfunction

% --- Update Compensator Gain from Edit Panel ---
function call_update_gain(~, ~)
  global h1 h3
  [z, p, ~] = zpkdata(h3.sys);
  k_str = get(h3.gain_box, 'String');
  k = str2num(k_str);

  if isempty(k)
    return;
  endif

  h3.sys = zpk(z, p, k);
  update_active_sys();

  if isfield(h3, 'select_compensator') && ishandle(h3.select_compensator) && get(h3.select_compensator, 'Value') == 1
    if isfield(h1, 'slider_gain') && ishandle(h1.slider_gain)
      current_max = get(h1.slider_gain, 'Max');
      if k > current_max
        new_max = 2 * k;
        set(h1.slider_gain, 'Max', new_max);
      endif
      set(h1.slider_gain, 'Value', k);
    endif
    if isfield(h1, 'txt_gain_val') && ishandle(h1.txt_gain_val)
      set(h1.txt_gain_val, 'String', num2str(k, '%.2f'));
    endif
  endif

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
    h1.G_str = v;
    if isfield(h1, 'lbl_arch_status') && ishandle(h1.lbl_arch_status)
      set(h1.lbl_arch_status, 'String', sprintf('Config %d | Plant updated successfully.', get_arch_idx()));
    endif
    refresh_all();
  catch err
    if isfield(h1, 'lbl_arch_status') && ishandle(h1.lbl_arch_status)
      set(h1.lbl_arch_status, 'String', ['Status Error: ', err.message]);
    endif
    errordlg(['Invalid Transfer Function syntax: ', err.message], 'Syntax Error');
  end_try_catch
endfunction

% --- Adjust Gain from Main Window Slider ---
function slider_adjustgain(src, ~)
  global h1 h3
  k = get(src, 'Value');
  [z, p, ~] = zpkdata(h1.C);
  h1.C = zpk(z, p, k);

  if isfield(h1, 'txt_gain_val') && ishandle(h1.txt_gain_val)
    set(h1.txt_gain_val, 'String', num2str(k, '%.2f'));
  endif

  if isfield(h3, 'gain_box') && ishandle(h3.gain_box)
    if ~isfield(h3, 'select_compensator') || ~ishandle(h3.select_compensator) || get(h3.select_compensator, 'Value') == 1
      set(h3.gain_box, 'String', num2str(k));
    endif
  endif

  refresh_all();
endfunction

function call_save_controller()
  global h1
  [num, den] = tfdata(h1.C, 'vector');

  if isfield(h1, 'list_num')
    n = length(h1.list_num) + 1;
    h1.list_num{n, 1} = num;
    h1.list_den{n, 1} = den;
    h1.flag_disp_C(n, 1) = 1;
  else
    h1.list_num = {num};
    h1.list_den = {den};
    h1.flag_disp_C = 1;
  endif

  update_design_listbox_strings();
  C = h1.C;
  save('controller.mat', 'C');
  set(h1.lbl_plant, 'String', 'Status: Controller saved.');
  plots();
endfunction

% --- Edit Architecture Callback ---
function call_menuarchitecture(~, ~)
  global fig4
  if exist('fig4', 'var') == 0 || isempty(fig4) || ~ishandle(fig4)
    editarchitecture();
  else
    set(fig4, 'Visible', 'on');
    figure(fig4);
    drawnow();
  endif
endfunction

% --- Main Plots Function with Multi-Architecture Support ---
function plots()
  global h1
  axes(h1.ax1); cla;

  if isfield(h1, 'flag_disp_C') == 0
    h1.flag_disp_C = 1;
    ii = 1;
  else
    ii = find(h1.flag_disp_C == 1);
  endif

  design_names = {};
  sys_cell = {};

  try
    if ~isempty(ii)
      for i = ii'
        if isfield(h1, 'list_num') && i <= length(h1.list_num)
          C_saved = tf(h1.list_num{i, :}, h1.list_den{i, :});
        else
          C_saved = h1.C;
        endif

        [sys_ol, sys_cl] = get_active_system_eval(C_saved);
        choice = get(h1.select_mainaxes, 'Value');
        switch choice
          case {1, 2}
            sys_cell{end+1} = sys_cl;
          case 3
            sys_cell{end+1} = C_saved / (1 + sys_ol);
        endswitch

        design_names{end+1} = sprintf('Design %d', i);
      endfor

      if ~isempty(sys_cell)
        choice = get(h1.select_mainaxes, 'Value');
        hold on;
        if choice == 1
          step(sys_cell{:});
          title('Closed-Loop Step Response');
        elseif choice == 2
          impulse(sys_cell{:});
          title('Closed-Loop Impulse Response');
        elseif choice == 3
          step(sys_cell{:});
          title('Control Effort Response');
        endif
        hold off;
        legend(design_names{:});
      endif
    else
      [sys_ol, sys_cl] = get_active_system_eval(h1.C);
      choice = get(h1.select_mainaxes, 'Value');
      switch choice
        case 1
          step(sys_cl);
          title('Closed-Loop Step Response (Active C)');
        case 2
          impulse(sys_cl);
          title('Closed-Loop Impulse Response (Active C)');
        case 3
          step(h1.C / (1 + sys_ol));
          title('Control Effort Response (Active C)');
      endswitch
    endif

    if isfield(h1, 'lbl_arch_status') && ishandle(h1.lbl_arch_status)
      set(h1.lbl_arch_status, 'String', sprintf('Architecture: Config %d | Status: Ready', get_arch_idx()));
    endif
  catch err
    cla(h1.ax1);
    if isfield(h1, 'lbl_arch_status') && ishandle(h1.lbl_arch_status)
      set(h1.lbl_arch_status, 'String', ['Status Error: ', err.message]);
    endif
  end_try_catch
endfunction

% --- Targeted Root Locus Plotter ---
function plotrlocus(target_ax)
  global h1 h2
  if nargin < 1 || isempty(target_ax), target_ax = h2.axrl; endif
  axes(target_ax);
  cla(target_ax);
  try
    [sys_ol, ~] = get_active_system_eval(h1.C);
    [num, den] = tfdata(sys_ol, 'vector');

    % Guard against systems with no poles (e.g., pure static gains)
    if length(den) < 2
      title(target_ax, sprintf('Root Locus (Config %d): System has no poles', get_arch_idx()));
      return;
    endif

    rlocus(sys_ol);
    title(target_ax, sprintf('Root Locus Diagram (Config %d)', get_arch_idx()));

    [olpol, olzer, ~] = getZP_local(h1.C);
    if ~isempty(olpol)
      hold(target_ax, 'on'); plot(target_ax, real(olpol), imag(olpol), 'x', 'markersize', 8, 'color', 'magenta', 'linewidth', 2); hold(target_ax, 'off');
    endif
    if ~isempty(olzer)
      hold(target_ax, 'on'); plot(target_ax, real(olzer), imag(olzer), 'o', 'markersize', 8, 'color', 'magenta', 'linewidth', 2); hold(target_ax, 'off');
    endif
  catch err
    warning(['Root locus error: ', err.message]);
  end_try_catch
endfunction

% --- Targeted Bode Plotter (Magnitude & Phase with Margins & Markers) ---
function plotbode(target_ax_m, target_ax_p)
  global h1 h2
  if nargin < 2
    target_ax_m = h2.axbm;
    target_ax_p = h2.axbp;
  endif
  cla(target_ax_m);
  cla(target_ax_p);
  try
    [sys_ol, ~] = get_active_system_eval(h1.C);
    [mag, phase, w] = bode(sys_ol);
    MAG = mag2db(squeeze(mag));
    PHA = squeeze(phase);

    % Magnitude plot
    semilogx(target_ax_m, w, MAG); grid(target_ax_m, 'on');
    ylabel(target_ax_m, 'Magnitude (dB)');
    title(target_ax_m, sprintf('Open-Loop Bode Diagram (Config %d)', get_arch_idx()));

    % Phase plot
    semilogx(target_ax_p, w, PHA); grid(target_ax_p, 'on');
    xlabel(target_ax_p, 'Frequency (rad/s)');
    ylabel(target_ax_p, 'Phase (deg)');

    % Mark poles and zeros on Bode curves
    [olpol, olzer, ~, ~] = getZP_local(sys_ol);
    poles_r = real(olpol)';
    poles_i = imag(olpol)';
    zeros_r = real(olzer)';
    zeros_i = imag(olzer)';

    wparray = sqrt(poles_r.^2 + poles_i.^2);
    wzarray = sqrt(zeros_r.^2 + zeros_i.^2);

    if (~isempty(wparray))
      idxp = ones(size(wparray));
      for i = 1:length(wparray)
        res = find(w <= wparray(i), 1, 'last');
        if ~isempty(res), idxp(i) = res; endif
      endfor
      hold(target_ax_m, 'on'); semilogx(target_ax_m, w(idxp), MAG(idxp), 'x', 'color', 'r', 'markersize', 8, 'linewidth', 4); hold(target_ax_m, 'off');
      hold(target_ax_p, 'on'); semilogx(target_ax_p, w(idxp), PHA(idxp), 'x', 'color', 'r', 'markersize', 8, 'linewidth', 4); hold(target_ax_p, 'off');
    endif

    if (~isempty(wzarray))
      idxz = ones(size(wzarray));
      for i = 1:length(wzarray)
        res = find(w <= wzarray(i), 1, 'last');
        if ~isempty(res), idxz(i) = res; endif
      endfor
      hold(target_ax_m, 'on'); semilogx(target_ax_m, w(idxz), MAG(idxz), 'o', 'color', 'g', 'markersize', 8, 'linewidth', 4); hold(target_ax_m, 'off');
      hold(target_ax_p, 'on'); semilogx(target_ax_p, w(idxz), PHA(idxz), 'o', 'color', 'g', 'markersize', 8, 'linewidth', 4); hold(target_ax_p, 'off');
    endif

    % Calculate gain and phase margins
    [Gm, Pm, Wgm, Wpm] = margin(sys_ol);

    Gm  = round(Gm*10)/10;
    Pm  = round(Pm*10)/10;
    Wgm = round(Wgm*10)/10;
    Wpm = round(Wpm*10)/10;

    descrm = {strcat('G.M:  ', num2str(Gm)); ...
              strcat('Freq:  ', num2str(Wgm))};

    descrp = {strcat('P.M:  ', num2str(Pm)); ...
              strcat('Freq:  ', num2str(Wpm))};

    % Display margins on Magnitude axis
    xLimM = get(target_ax_m, 'XLim');
    yLimM = get(target_ax_m, 'YLim');
    text(target_ax_m, 10^(log10(xLimM(1)) + 0.05*(log10(xLimM(2)) - log10(xLimM(1)))), ...
         yLimM(1) + 0.2*(yLimM(2) - yLimM(1)), descrm);

    % Display margins on Phase axis
    xLimP = get(target_ax_p, 'XLim');
    yLimP = get(target_ax_p, 'YLim');
    text(target_ax_p, 10^(log10(xLimP(1)) + 0.05*(log10(xLimP(2)) - log10(xLimP(1)))), ...
         yLimP(1) + 0.2*(yLimP(2) - yLimP(1)), descrp);
  catch err
    warning(['Bode plot error: ', err.message]);
  end_try_catch
endfunction

% --- Targeted Nyquist Plotter ---
function plotnyquist(target_ax)
  global h1 h2
  if nargin < 1 || isempty(target_ax), target_ax = h2.axny; endif
  axes(target_ax);
  cla(target_ax);
  try
    [sys_ol, ~] = get_active_system_eval(h1.C);
    nyquist(sys_ol);
    title(target_ax, sprintf('Nyquist Diagram (Config %d)', get_arch_idx()));
  catch err
    warning(['Nyquist plot error: ', err.message]);
  end_try_catch
endfunction

function plot_all()
  global h2
  if ~isfield(h2, 'panel_all') || ~ishandle(h2.panel_all)
    return;
  endif
  plotrlocus(h2.ax_all_rl);
  plotbode(h2.ax_all_bm, h2.ax_all_bp);
  plotnyquist(h2.ax_all_ny);
endfunction

function idx = get_arch_idx()
  global h1
  if isfield(h1, 'architecture_idx') && ~isempty(h1.architecture_idx)
    idx = h1.architecture_idx;
  else
    idx = 1;
  endif
endfunction

function close_all(varargin)
  close all force;
  clear all global;
endfunction

% --- Helper to format polynomial coefficients into text ---
function s = poly2str_custom(c)
  n = length(c);
  s = '';
  is_first = true;
  for i = 1:n
    p = n - i;
    val = c(i);
    if abs(val) < 1e-12 && n > 1
      continue;
    endif

    val_abs = abs(val);
    if is_first
      if val < 0
        s = [s, '-'];
      endif
      is_first = false;
    else
      if val > 0
        s = [s, ' + '];
      elseif val < 0
        s = [s, ' - '];
      else
        continue;
      endif
    endif

    if p > 0
      if abs(val_abs - 1) > 1e-12
        s = [s, num2str(val_abs)];
      endif
      if p == 1
        s = [s, 's'];
      else
        s = [s, 's^', num2str(p)];
      endif
    else
      s = [s, num2str(val_abs)];
    endif
  endfor
  if isempty(s)
    s = '0';
  endif
endfunction
