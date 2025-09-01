% 入力：サンプリング周波数[Hz]
% 入力：計測時間[sec]
Fs = 1000;
sec = 120;

% 入力：拡張子
% 同じ階層にあるこの拡張子のファイル情報をリスト化する
list = dir('*.csv');

% table作成
sz = [length(list) 13];
varTypes = ["string","double","double","double","double","double","double","double"...
    "double","double","double","double","double"];
varNames = ["name","1","2","3","4","5","6","7","8","9","10","11","12"];
MPF_table = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

for m = 1:length(list)
    
    % リストのm行目のname列をファイル名として指定する
    % 入力：区切り文字
    % 入力：ヘッダ部分の行数
    filename = list(m).name;
    delimiterIn = ',';
    headerlinesIn = 12;
    
    % MPF_tableの1列目にファイル名を代入
    MPF_table(m,1) = {list(m).name};

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
    
    MPF_table(m,1) = {list(m).name};
    
    % 時間変化MPFを求める
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
     
        % rawをiからjまで取り出してextracted_rawとする
        extracted_raw = raw(i:j,:);
    
        % FFT
        % フーリエスペクトルの算出
        % パワースペクトルへの変換と正規化
        % 周波数解像度の設定
        % 正の周波数領域（片側スペクトル）の抽出
        rawfft = fft(extracted_raw);
        pow_fftdata = abs(rawfft).^2/length(rawfft);
        freq = 0:Fs/(length(pow_fftdata)-1):Fs/2;
        Pow = [pow_fftdata(1); 2*pow_fftdata(2:length(freq))];
        
        % 平均周波数の算出
        MPF_time = freq*Pow/sum(Pow);
            
        % MPF_tableに代入
        MPF_table(m,k+1) = {MPF_time};
        
        % 取り出す範囲をずらす
        i = i + data_step_size;
        j = j + data_step_size;
    
    end
end