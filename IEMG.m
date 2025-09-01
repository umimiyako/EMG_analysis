% 入力：サンプリング周波数[Hz]
% 入力：計測時間[sec]
Fs = 1000;
sec = 120;

% 入力：拡張子
% 同じ階層にあるこの拡張子のファイル情報をリスト化する
list = dir('*.csv');

% table作成
sz = [length(list) 14];
varTypes = ["string","double","double","double","double","double","double","double"...
    "double","double","double","double","double","double"];
varNames = ["name","IEMG","1","2","3","4","5","6","7","8","9","10","11","12"];
IEMG_table = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

for m = 1:length(list)
    
    % リストのm行目のname列をファイル名として指定する
    % 入力：区切り文字
    % 入力：ヘッダ部分の行数
    filename = list(m).name;
    delimiterIn = ',';
    headerlinesIn = 12;
    
    % IEMG_tableの1列目にファイル名を代入
    IEMG_table(m,1) = {list(m).name};

    % データを取り込んでemgとする
    % emgの2列目を取り出してraw_columnとする
    % データ数nの計算
    % raw_columnを1からn行まで取り出してraw_noise_trendとする
    emg = importdata(filename,delimiterIn,headerlinesIn);
    raw_column = emg.data(:,2);
    n = sec*Fs;
    raw_noise_trend = raw_column(1:n,:);
    
    % 標準偏差の3倍を超えて平均値から離れている要素を外れ値として検出し，1つ前の非外れ値に置き換える
    % 直流成分を除去
    raw_trend = filloutliers(raw_noise_trend,"previous","mean");
    raw = detrend(raw_trend);

    % 時刻インデックスの作成
    tind = (1:n)/Fs;

    % RMSによる整流・平滑化
    % 入力：積分区間（データ点数）
    % サンプリング周波数の1/20か1/10にする
    wlength = 100;
    smooth = zeros(size(raw));
    
    % 積分区間データ長が偶数の場合，時間窓を積分時刻を中心に
    % 左右対称とするため窓長を1増加させる
    if mod(wlength, 2) == 0 
        wlength = wlength+1; 
    end
    
    % 時間窓の片側長さ
    % データ長
    nedge = floor(wlength/2);
    dlen = length(raw);
    
    % RMSの計算
    for ii = 1:dlen
    
        % データの左端
        if(ii <= nedge)
            smooth(ii,1) = rms(raw(1:(ii+nedge), 1));
        end
    
        if(ii > nedge && ii < dlen - nedge)
            smooth(ii,1) = rms(raw((ii-nedge):(ii+nedge), 1));
        end
    
        % データの左端
        if(ii >= dlen - nedge)
            smooth(ii,1) = rms(raw((ii-nedge):dlen, 1));
        end
    
    end
    
    % IEMGを求める
    % IEMG_tableに代入
    iemg = sum(smooth(1:length(smooth), 1));
    IEMG_table(m,2) = {iemg};
    
    % 時間変化IEMGを求める
    % 入力：時間刻み幅 [秒]
    % データ刻み幅を計算
    % 時間帯個数を計算
    time_step_size = 30;
    data_step_size = time_step_size*Fs;
    quantity = sec/time_step_size;
    
    % 変数i,jの初期値を設定
    i = 1;
    j = data_step_size;
    
    % 変数kを1からquantityまで変化させる
    for k = 1:quantity
        
        % smoothをiからjまで取り出してextracted_smoothとする
        % IEMG_timeを計算
        % IEMG_timeをIEMG_tableに代入
        extracted_smooth = smooth(i:j,:);
        IEMG_time = sum(extracted_smooth(1:length(extracted_smooth), 1));
        IEMG_table(m,k+2) = {IEMG_time};
        
        % 取り出す範囲をずらす
        i = i + data_step_size;
        j = j + data_step_size;
    
    end
end