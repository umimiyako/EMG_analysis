% 入力：サンプリング周波数[Hz]
% 入力：計測時間[sec]
% 入力；x軸目盛り幅
Fs = 1000;
sec = 120;
xsw = 10;

% 入力：拡張子
% 同じ階層にあるこの拡張子のファイル情報をリスト化する
list = dir('*.csv');

for m = 1:length(list)
    
    % リストのm行目のname列をファイル名として指定する
    % 入力：区切り文字
    % 入力：ヘッダ部分の行数
    filename = list(m).name;
    delimiterIn = ',';
    headerlinesIn = 12;

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

    % RMS波形をプロット
    figure('Name',list(m).name);
    plot(tind,smooth,"k");
    
    % 軸ラベル設定
    xlabel('Time [s]','FontSize',12,'FontName','Times New Roman'); 
    ylabel('Voltage [mV]','FontSize',12,'FontName','Times New Roman');
    
    % 入力：軸範囲
    % 入力：目盛り幅
    % 入力：y軸小数点以下の桁数
    % 入力：目盛り値の設定
    % 入力：figureのxyz方向の大きさの固定比
    xlim([0 sec]);
    ylim([0 0.5]);
    xticks(0:xsw:sec)
    yticks(0:0.1:0.5)
    ytickformat('%.2f');
    set(gca,'FontSize',12,'FontName','Times New Roman');
    pbaspect([1.4 1 1])
    
    % ファイル名を指定
    % 指定したファイル名からパス・名前・拡張子を取得
    file = list(m).name;
    [filepath,name,ext] = fileparts(file);

    % 入力：保存するファイル形式
    % ファイルの名前を保存名にする
    % stringスカラーを結合してsnとする
    extension = ".pdf";
    fn = name;
    sn = append(fn,extension);
    
    % snという名前で保存
    % ベクトルグラフィックスで保存
    % 1200dpiで保存
    exportgraphics(gcf,sn,"ContentType","vector",'Resolution',1200)
end